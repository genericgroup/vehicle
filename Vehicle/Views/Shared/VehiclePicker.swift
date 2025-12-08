import SwiftUI

/// A reusable picker for selecting a vehicle from a list
struct VehiclePicker: View, Equatable {
    let vehicles: [Vehicle]
    @Binding var selectedVehicle: Vehicle?
    var label: String = "Vehicle*"
    var placeholder: String = "Select Vehicle"
    var accessibilityHint: String = "Select a vehicle"
    var includeHapticFeedback: Bool = true
    
    var body: some View {
        Picker(label, selection: Binding(
            get: { selectedVehicle },
            set: { newValue in
                if includeHapticFeedback {
                    HapticManager.standardSelectionChanged()
                }
                selectedVehicle = newValue
            }
        )) {
            Text(placeholder).tag(nil as Vehicle?)
            ForEach(vehicles) { vehicle in
                Text(vehicle.displayName).tag(vehicle as Vehicle?)
            }
        }
        .accessibilityLabel(label.replacingOccurrences(of: "*", with: ""))
        .accessibilityHint(accessibilityHint)
        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
    }
    
    static func == (lhs: VehiclePicker, rhs: VehiclePicker) -> Bool {
        lhs.vehicles == rhs.vehicles &&
        lhs.selectedVehicle?.id == rhs.selectedVehicle?.id &&
        lhs.label == rhs.label
    }
}

#Preview {
    Form {
        VehiclePicker(
            vehicles: [],
            selectedVehicle: .constant(nil)
        )
    }
}
