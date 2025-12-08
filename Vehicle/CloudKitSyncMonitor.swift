import SwiftUI
import CloudKit
import CoreData
import Combine

/// Monitors CloudKit sync status for SwiftData.
/// Note: SwiftData with CloudKit uses NSPersistentCloudKitContainer under the hood,
/// so we can still observe its sync events via the same notification.
@MainActor
class CloudKitSyncMonitor: ObservableObject {
    enum SyncStatus: Equatable {
        case notStarted
        case inProgress
        case succeeded
        case failed(String)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted): return true
            case (.inProgress, .inProgress): return true
            case (.succeeded, .succeeded): return true
            case (.failed(let lhsError), .failed(let rhsError)): return lhsError == rhsError
            default: return false
            }
        }
    }
    
    @Published private(set) var syncStatus: SyncStatus = .notStarted
    @Published private(set) var lastSyncTime: Date?
    
    private var cancellable: AnyCancellable?
    private let logger = AppLogger.shared
    
    init() {
        // SwiftData with CloudKit still uses NSPersistentCloudKitContainer internally,
        // so we can observe its sync events via the same notification
        cancellable = NotificationCenter.default.publisher(
            for: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let self = self else { return }
            self.handleCloudKitEvent(notification)
        }
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let cloudEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        switch cloudEvent.type {
        case .setup:
            handleSetupEvent(cloudEvent)
        case .import:
            handleImportEvent(cloudEvent)
        case .export:
            handleExportEvent(cloudEvent)
        @unknown default:
            logger.warning("Unknown CloudKit sync event type: \(cloudEvent.type.rawValue)", category: .sync)
        }
    }
    
    private func handleSetupEvent(_ event: NSPersistentCloudKitContainer.Event) {
        switch event.endDate {
        case .none:
            syncStatus = .inProgress
            logger.debug("Starting CloudKit setup...", category: .sync)
        case .some(_):
            if let error = event.error {
                syncStatus = .failed(error.localizedDescription)
                logger.error("CloudKit setup failed: \(error.localizedDescription)", category: .sync)
            } else {
                syncStatus = .succeeded
                lastSyncTime = event.endDate
                logger.info("CloudKit setup completed successfully", category: .sync)
            }
        }
    }
    
    private func handleImportEvent(_ event: NSPersistentCloudKitContainer.Event) {
        switch event.endDate {
        case .none:
            syncStatus = .inProgress
            logger.debug("Starting CloudKit import...", category: .sync)
        case .some(_):
            if let error = event.error {
                syncStatus = .failed(error.localizedDescription)
                logger.error("CloudKit import failed: \(error.localizedDescription)", category: .sync)
            } else {
                syncStatus = .succeeded
                lastSyncTime = event.endDate
                logger.info("CloudKit import completed successfully", category: .sync)
            }
        }
    }
    
    private func handleExportEvent(_ event: NSPersistentCloudKitContainer.Event) {
        switch event.endDate {
        case .none:
            syncStatus = .inProgress
            logger.debug("Starting CloudKit export...", category: .sync)
        case .some(_):
            if let error = event.error {
                syncStatus = .failed(error.localizedDescription)
                logger.error("CloudKit export failed: \(error.localizedDescription)", category: .sync)
            } else {
                syncStatus = .succeeded
                lastSyncTime = event.endDate
                logger.info("CloudKit export completed successfully", category: .sync)
            }
        }
    }
} 