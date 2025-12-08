import Foundation

/// Type-safe keys for @AppStorage to prevent typos and ensure consistency
enum AppStorageKeys {
    // MARK: - Vehicle List Display
    
    /// Key for vehicle sort option (stores VehicleSortOption.rawValue)
    static let vehicleSortOption = "vehicleSortOption"
    
    /// Key for vehicle group option (stores VehicleGroupOption.rawValue)
    static let vehicleGroupOption = "vehicleGroupOption"
    
    /// Key for showing nicknames in vehicle list
    static let showNicknamesInList = "showNicknamesInList"
    
    /// Key for showing icons in vehicle list and title bar
    static let showIconsInList = "showIconsInList"
    
    // MARK: - User Preferences
    
    /// Key for preferred distance unit
    static let preferredDistanceUnit = "preferredDistanceUnit"
    
    /// Key for preferred currency code
    static let preferredCurrencyCode = "preferredCurrencyCode"
    
    // MARK: - App State
    
    /// Key for last selected vehicle ID
    static let lastSelectedVehicleId = "lastSelectedVehicleId"
    
    /// Key for onboarding completion status
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    
    /// Key for last app version (for detecting updates)
    static let lastAppVersion = "lastAppVersion"
}
