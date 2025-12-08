import SwiftUI

// MARK: - Shared Field Type
enum FormField {
    case details, mileage, hours, cost
}

struct MetricsFormView: View {
    @Binding var mileage: String
    @Binding var distanceUnit: DistanceUnit
    @Binding var hours: String
    @Binding var cost: String
    @Binding var currencyCode: String
    let currencyCodes: [String]
    @FocusState.Binding var focusedField: FormField?
    
    var body: some View {
        Section {
            HStack {
                TextField("Mileage", text: Binding(
                    get: { mileage },
                    set: { 
                        let formatted = VehicleValidation.formatDecimalForDisplay(VehicleValidation.parseAndRoundDecimal($0))
                        if formatted != mileage {
                            mileage = formatted
                        }
                    }
                ))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .mileage)
                    .accessibilityLabel("Event mileage")
                    .accessibilityHint("Enter the mileage at the time of this event")
                
                Picker("", selection: $distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .labelsHidden()
            }
            .frame(height: ViewConstants.rowHeight)
            
            TextField("Hours", text: Binding(
                get: { hours },
                set: { 
                    let formatted = VehicleValidation.formatDecimalForDisplay(VehicleValidation.parseAndRoundDecimal($0))
                    if formatted != hours {
                        hours = formatted
                    }
                }
            ))
                .keyboardType(.decimalPad)
                .frame(height: ViewConstants.rowHeight)
                .focused($focusedField, equals: .hours)
                .accessibilityLabel("Event hours")
                .accessibilityHint("Enter the number of hours for this event")
            
            HStack {
                TextField("Cost", text: Binding(
                    get: { cost },
                    set: { 
                        let formatted = VehicleValidation.formatDecimalForDisplay(VehicleValidation.parseAndRoundDecimal($0))
                        if formatted != cost {
                            cost = formatted
                        }
                    }
                ))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .cost)
                    .accessibilityLabel("Event cost")
                    .accessibilityHint("Enter the cost of this event")
                
                Picker("", selection: $currencyCode) {
                    ForEach(currencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .labelsHidden()
            }
            .frame(height: ViewConstants.rowHeight)
        } header: {
            Text("METRICS")
                .textCase(.uppercase)
                .font(.subheadline)
                .dynamicTypeSize(ViewConstants.dynamicTypeRange)
        }
    }
} 