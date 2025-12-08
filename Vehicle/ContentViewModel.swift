import SwiftUI
import Combine
import UIKit
import SwiftData

// MARK: - Error Types
enum ContentViewError: LocalizedError {
    case modelContextNotSet
    case databaseError(Error)
    case vehicleNotFound
    case invalidOperation(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelContextNotSet:
            return "Database context not initialized"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .vehicleNotFound:
            return "Vehicle not found"
        case .invalidOperation(let description):
            return description
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var showingAddVehicle = false
    @Published var showingAddEvent = false
    @Published var showingAddOwnership = false
    @Published var showingSettings = false
    @Published var showingNoVehiclesError = false
    @Published var currentError: ContentViewError?
    @Published var showingError = false
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger.shared
    private var modelContext: ModelContext?
    
    // Haptic feedback generators
    let notificationHaptics = UINotificationFeedbackGenerator()
    let selectionHaptics = UIImpactFeedbackGenerator(style: .light)
    let mediumImpactHaptics = UIImpactFeedbackGenerator(style: .medium)
    let heavyImpactHaptics = UIImpactFeedbackGenerator(style: .heavy)
    
    init() {
        logger.info("ContentViewModel initialized", category: .userInterface)
        setupNotificationObservers()
        prepareHaptics()
    }
    
    func prepareHaptics() {
        notificationHaptics.prepare()
        selectionHaptics.prepare()
        mediumImpactHaptics.prepare()
        heavyImpactHaptics.prepare()
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: ContentViewError) {
        logger.error(error.localizedDescription, category: .userInterface)
        currentError = error
        showingError = true
        triggerErrorHaptic()
    }
    
    private func handleDatabaseError(_ error: Error, operation: String) {
        let contentError = ContentViewError.databaseError(error)
        logger.error("\(operation) failed: \(error.localizedDescription)", category: .database)
        handleError(contentError)
    }
    
    // MARK: - Database Operations
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        logger.info("Model context set in ContentViewModel", category: .database)
    }
    
    private func checkForVehicles() -> Bool {
        guard let context = modelContext else {
            handleError(.modelContextNotSet)
            return false
        }
        
        do {
            var descriptor = FetchDescriptor<Vehicle>()
            descriptor.fetchLimit = 1
            let vehicles = try context.fetch(descriptor)
            logger.debug("Found \(vehicles.isEmpty ? "no" : "some") vehicles in database", category: .database)
            return !vehicles.isEmpty
        } catch {
            handleDatabaseError(error, operation: "Checking for vehicles")
            return false
        }
    }
    
    // MARK: - Haptic Feedback Methods
    
    func triggerAddHaptic() {
        logger.debug("Triggered add action haptic feedback", category: .userInterface)
        notificationHaptics.notificationOccurred(.success)
    }
    
    func triggerDeleteHaptic() {
        logger.debug("Triggered delete action haptic feedback", category: .userInterface)
        notificationHaptics.notificationOccurred(.error)
    }
    
    func triggerErrorHaptic() {
        logger.debug("Triggered error haptic feedback", category: .userInterface)
        notificationHaptics.notificationOccurred(.error)
    }
    
    func triggerWarningHaptic() {
        logger.debug("Triggered warning haptic feedback", category: .userInterface)
        notificationHaptics.notificationOccurred(.warning)
    }
    
    func triggerPinHaptic() {
        logger.debug("Triggered pin action haptic feedback", category: .userInterface)
        mediumImpactHaptics.impactOccurred(intensity: 0.7)
    }
    
    func triggerSelectionHaptic() {
        logger.debug("Triggered selection haptic feedback", category: .userInterface)
        selectionHaptics.impactOccurred()
    }
    
    func triggerMediumImpactHaptic() {
        logger.debug("Triggered medium impact haptic feedback", category: .userInterface)
        mediumImpactHaptics.impactOccurred()
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        // Set up notification observers using Combine
        NotificationCenter.default.publisher(for: .showAddVehicle)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("Received showAddVehicle notification", category: .userInterface)
                self.triggerAddHaptic()
                self.showingAddVehicle = true
                UIAccessibility.post(notification: .announcement, argument: "Opening Add Vehicle Form")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .showAddEvent)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("Received showAddEvent notification", category: .userInterface)
                if self.checkForVehicles() {
                    self.triggerAddHaptic()
                    self.showingAddEvent = true
                    UIAccessibility.post(notification: .announcement, argument: "Opening Add Event Form")
                } else {
                    self.triggerWarningHaptic()
                    self.showingNoVehiclesError = true
                    UIAccessibility.post(notification: .announcement, argument: "Cannot add event. No vehicles found.")
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .showAddOwnership)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("Received showAddOwnership notification", category: .userInterface)
                if self.checkForVehicles() {
                    self.triggerAddHaptic()
                    self.showingAddOwnership = true
                    UIAccessibility.post(notification: .announcement, argument: "Opening Add Ownership Record Form")
                } else {
                    self.triggerWarningHaptic()
                    self.showingNoVehiclesError = true
                    UIAccessibility.post(notification: .announcement, argument: "Cannot add ownership record. No vehicles found.")
                }
            }
            .store(in: &cancellables)
    }
    
    private var hasVehicles = false
    
    func updateVehiclesState(hasVehicles: Bool) {
        let oldValue = self.hasVehicles
        self.hasVehicles = hasVehicles
        
        if oldValue != hasVehicles {
            logger.info("Vehicle state changed: \(hasVehicles ? "has vehicles" : "no vehicles")", category: .userInterface)
        }
    }
    
    // MARK: - Accessibility Helpers
    
    func announceForAccessibility(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
} 