import SwiftUI

enum VehicleDisplayHelper {
    static func vehicleDisplayName(_ vehicle: Vehicle, inGroup option: VehicleGroupOption) -> String {
        switch option {
        case .year:
            return "\(vehicle.make) \(vehicle.model)\(vehicle.nickname.map { " (\($0))" } ?? "")"
        case .make:
            return "\(vehicle.year) \(vehicle.model)\(vehicle.nickname.map { " (\($0))" } ?? "")"
        case .category:
            return "\(vehicle.year) \(vehicle.make) \(vehicle.model)\(vehicle.nickname.map { " (\($0))" } ?? "")"
        case .none:
            return vehicle.displayName
        }
    }
    
    static func vehicleSecondaryText(_ vehicle: Vehicle, inGroup option: VehicleGroupOption) -> String? {
        switch option {
        case .category:
            return nil // Don't show category as it's the group header
        case .make:
            return vehicle.category.displayName
        case .year:
            return vehicle.category.displayName
        case .none:
            return vehicle.category.displayName
        }
    }
    
    static func groupVehicles(_ vehicles: [Vehicle], option: VehicleGroupOption) -> [(String, [Vehicle])] {
        // Split vehicles into pinned and unpinned
        let pinnedVehicles = vehicles.filter { $0.isPinned }
        let unpinnedVehicles = vehicles.filter { !$0.isPinned }
        
        // Create sections based on grouping option
        let unpinnedSections: [(String, [Vehicle])] = {
            switch option {
            case .none:
                return unpinnedVehicles.isEmpty ? [] : [("All Vehicles", unpinnedVehicles)]
            case .category:
                return Dictionary(grouping: unpinnedVehicles) { $0.category.displayName }
                    .map { ($0.key, $0.value) }
                    .sorted { $0.0 < $1.0 }
            case .make:
                return Dictionary(grouping: unpinnedVehicles) { $0.make.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .map { ($0.key.isEmpty ? "Unnamed" : $0.key, $0.value) }
                    .sorted { $0.0 < $1.0 }
            case .year:
                return Dictionary(grouping: unpinnedVehicles) { String($0.year) }
                    .map { ($0.key, $0.value) }
                    .sorted { $0.0 > $1.0 }
            }
        }()
        
        // Only add pinned section if there are pinned vehicles
        return pinnedVehicles.isEmpty ? unpinnedSections : [("Pinned", pinnedVehicles)] + unpinnedSections
    }
} 