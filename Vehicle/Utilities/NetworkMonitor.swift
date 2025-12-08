import Foundation
import Network
import CloudKit
import SwiftUI

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let logger = AppLogger.shared
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected = false
    var connectionType = NWInterface.InterfaceType.other
    var isCloudKitAvailable = true
    var lastSyncAttempt: Date?
    var syncRetryCount = 0
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 5
    
    private init() {
        setupNetworkMonitoring()
        setupCloudKitNotifications()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.connectionType = path.availableInterfaces.first?.type ?? .other
                
                // Log network status changes
                self.logger.info(
                    "Network status changed - Connected: \(self.isConnected), Type: \(self.connectionType)",
                    category: .state
                )
                
                if self.isConnected {
                    self.checkPendingSyncs()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func setupCloudKitNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitNotification(_:)),
            name: NSNotification.Name.CKAccountChanged,
            object: nil
        )
    }
    
    @objc private func handleCloudKitNotification(_ notification: Notification) {
        checkCloudKitAvailability()
    }
    
    func checkCloudKitAvailability() {
        CKContainer.default().accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let wasAvailable = self.isCloudKitAvailable
                self.isCloudKitAvailable = status == .available
                
                if wasAvailable != self.isCloudKitAvailable {
                    self.logger.info(
                        "CloudKit availability changed: \(self.isCloudKitAvailable)",
                        category: .state
                    )
                }
                
                if let error = error {
                    self.logger.error(
                        "CloudKit status check failed: \(error.localizedDescription)",
                        category: .database
                    )
                }
                
                if self.isCloudKitAvailable {
                    self.checkPendingSyncs()
                }
            }
        }
    }
    
    func performCloudKitOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        do {
            lastSyncAttempt = Date()
            return try await operation()
        } catch {
            logger.error(
                "CloudKit operation failed: \(error.localizedDescription)",
                category: .database
            )
            
            if shouldRetry(error) {
                return try await retryOperation(operation)
            }
            throw error
        }
    }
    
    private func shouldRetry(_ error: Error) -> Bool {
        guard syncRetryCount < maxRetries else {
            logger.warning(
                "Max retry attempts reached (\(maxRetries))",
                category: .database
            )
            return false
        }
        
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkFailure,
                 .networkUnavailable,
                 .serverResponseLost,
                 .serviceUnavailable,
                 .requestRateLimited:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    private func retryOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        syncRetryCount += 1
        
        logger.info(
            "Retrying CloudKit operation (attempt \(syncRetryCount)/\(maxRetries))",
            category: .database
        )
        
        try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(syncRetryCount) * 1_000_000_000))
        
        return try await performCloudKitOperation(operation)
    }
    
    private func checkPendingSyncs() {
        guard isConnected && isCloudKitAvailable else { return }
        
        // Reset retry count when network becomes available
        syncRetryCount = 0
        
        // Notify the system that sync can proceed
        NotificationCenter.default.post(
            name: .cloudKitSyncAvailable,
            object: nil
        )
    }
    
    func resetSyncState() {
        syncRetryCount = 0
        lastSyncAttempt = nil
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let cloudKitSyncAvailable = Notification.Name("cloudKitSyncAvailable")
}

// MARK: - View Extension
extension View {
    func handleCloudKitSync(
        isPresented: Binding<Bool>,
        retryAction: @escaping () -> Void
    ) -> some View {
        self.alert("Sync Error", isPresented: isPresented) {
            Button("Retry") {
                retryAction()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("There was a problem syncing with iCloud. Would you like to try again?")
        }
    }
} 