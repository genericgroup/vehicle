import SwiftUI
import SwiftData

extension OwnershipEventType {
    var guidance: (title: String, details: [String]) {
        switch self {
        case .purchased:
            return (
                "Purchased: Captures the acquisition of a vehicle.",
                [
                    "Financing or Lease Details: Whether the vehicle was financed, leased, or purchased outright.",
                    "Trade-In Information: Details of any vehicle traded in as part of the purchase.",
                    "Dealer/Private Party Information: Seller's name and location.",
                    "Warranty Information: Coverage details, duration, and start date."
                ]
            )
        case .sold:
            return (
                "Sold: Tracks when the vehicle is sold.",
                [
                    "Buyer Information: Name and contact details.",
                    "Sale Price: Amount the vehicle was sold for.",
                    "Bill of Sale: Option to attach a copy of the bill of sale."
                ]
            )
        case .registered:
            return (
                "Registered: Tracks the registration status of the vehicle.",
                [
                    "Registration Expiry: When the current registration expires.",
                    "Registration State or Country: Useful for vehicles used across regions.",
                    "Registration Type: Commercial, private, historic, etc."
                ]
            )
        case .insured:
            return (
                "Insured: Tracks the insurance coverage for the vehicle.",
                [
                    "Policy Number: Unique identifier for the insurance policy.",
                    "Coverage Type: Comprehensive, collision, liability-only, etc.",
                    "Expiry Date: When the insurance policy expires.",
                    "Insurer: Name of the insurance company."
                ]
            )
        case .leased:
            return (
                "Leased: Tracks lease agreements for the vehicle.",
                [
                    "Lessor Information: Leasing company or entity.",
                    "Lease Term: Start and end dates.",
                    "Monthly Payment: Payment amount and frequency.",
                    "Residual Value: Buyout cost at the end of the lease."
                ]
            )
        case .gifted:
            return (
                "Gifted: Tracks when a vehicle is given or received as a gift.",
                [
                    "Giver/Recipient Information: Name and contact details.",
                    "Reason or Occasion: Optional context for the gift (e.g., birthday, anniversary)."
                ]
            )
        case .scrapped:
            return (
                "Scrapped/Retired: Tracks when a vehicle is taken out of service or scrapped.",
                [
                    "Date of Retirement: When the vehicle was scrapped.",
                    "Reason for Retirement: Damaged, totaled, obsolete, etc.",
                    "Scrapping Facility: Name and location of the facility."
                ]
            )
        case .loaned:
            return (
                "Loaned: Tracks when the vehicle is temporarily loaned to someone else.",
                [
                    "Borrower Information: Name and contact details.",
                    "Loan Duration: Start and end dates.",
                    "Agreement Details: Terms of the loan."
                ]
            )
        case .transferred:
            return (
                "Transferred: Tracks ownership transfers not covered under \"Sold\" or \"Gifted.\"",
                [
                    "Transfer Type: Inheritance, legal transfer, or other.",
                    "Transfer Details: Reason and parties involved."
                ]
            )
        case .exported:
            return (
                "Exported: Tracks when a vehicle is exported to another country.",
                [
                    "Export Destination: Country or region.",
                    "Export Date: Date the vehicle was exported.",
                    "Export Reason: Sale, relocation, or other."
                ]
            )
        default:
            return (
                "Ownership Record",
                [
                    "Record any relevant details about this ownership event.",
                    "Include dates, parties involved, and any supporting documentation."
                ]
            )
        }
    }
}

// MARK: - Main View
struct AddOwnershipView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Vehicle.year, order: .reverse),
        SortDescriptor(\Vehicle.make),
        SortDescriptor(\Vehicle.model)
    ]) private var vehicles: [Vehicle]
    
    // MARK: - State Management
    @State private var selectedVehicle: Vehicle?
    @State private var date = Date()
    @State private var selectedType = OwnershipEventType.purchased
    @State private var details = ""
    @State private var mileage = ""
    @State private var distanceUnit = DistanceUnit.miles
    @State private var hours = ""
    @State private var cost = ""
    @State private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: FormField?
    
    private let logger = AppLogger.shared
    private let currencyCodes = Locale.commonISOCurrencyCodes
    
    init(selectedVehicle: Vehicle? = nil) {
        _selectedVehicle = State(initialValue: selectedVehicle)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VehiclePicker(
                        vehicles: vehicles,
                        selectedVehicle: $selectedVehicle,
                        accessibilityHint: "Select a vehicle for this record"
                    )
                    .frame(height: ViewConstants.rowHeight)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .frame(height: ViewConstants.rowHeight)
                        .accessibilityLabel("Record date")
                        .accessibilityHint("Select the date of this ownership event")
                        .standardDynamicTypeSize()
                    
                    Picker("Type", selection: Binding(
                        get: { selectedType },
                        set: { 
                            HapticManager.standardSelectionChanged()
                            selectedType = $0 
                        }
                    )) {
                        ForEach(OwnershipEventType.allTypes, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .frame(height: ViewConstants.rowHeight)
                    .accessibilityLabel("Record type")
                    .accessibilityHint("Select the type of ownership record")
                    .standardDynamicTypeSize()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType.guidance.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(selectedType.guidance.details, id: \.self) { detail in
                            Text("• " + detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 16)
                    .listRowSeparator(.hidden)
                    .standardDynamicTypeSize()
                    .accessibilityLabel("Record type guidance")
                    
                    VStack(alignment: .leading) {
                        Text("Details*")
                            .font(.callout)
                            .standardDynamicTypeSize()
                        TextEditor(text: $details)
                            .frame(height: ViewConstants.textEditorHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .focused($focusedField, equals: .details)
                            .accessibilityLabel("Record details")
                            .accessibilityHint("Enter the details of this ownership record")
                    }
                } header: {
                    Text("RECORD DETAILS")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .standardDynamicTypeSize()
                } footer: {
                    Text("* Required")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .standardDynamicTypeSize()
                        .textCase(nil)
                }
                
                MetricsFormView(
                    mileage: $mileage,
                    distanceUnit: $distanceUnit,
                    hours: $hours,
                    cost: $cost,
                    currencyCode: $currencyCode,
                    currencyCodes: currencyCodes,
                    focusedField: $focusedField
                )
            }
            .standardNavigationBar(title: "Add Record")
            .standardFormStyle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.standardButtonTap()
                        logger.info("User cancelled adding ownership record", category: .userInterface)
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discard this record and return to the previous screen")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        HapticManager.standardButtonTap()
                        addRecord()
                    }
                    .disabled(selectedVehicle == nil || details.isEmpty)
                    .accessibilityLabel("Add Record")
                    .accessibilityHint("Save this ownership record")
                }
            }
            .standardKeyboardDoneButton(focusedField: $focusedField)
            .alert("Validation Error", isPresented: $showingError) {
                Button("OK") {
                    HapticManager.standardButtonTap()
                    showingError = false
                    // Focus the field that caused the error if possible
                    if errorMessage.contains("details") {
                        focusedField = .details
                    } else if errorMessage.contains("mileage") {
                        focusedField = .mileage
                    } else if errorMessage.contains("hours") {
                        focusedField = .hours
                    } else if errorMessage.contains("cost") {
                        focusedField = .cost
                    }
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addRecord() {
        // Validate vehicle selection
        guard let vehicle = selectedVehicle else {
            errorMessage = "Please select a vehicle"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate date
        let dateValidation = OwnershipValidation.validateDate(date)
        if !dateValidation.isValid {
            errorMessage = dateValidation.message ?? "Invalid date"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate details
        let detailsValidation = OwnershipValidation.validateDetails(details, type: selectedType)
        if !detailsValidation.isValid {
            errorMessage = detailsValidation.message ?? "Invalid details"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate required fields based on type
        let requiredFieldsValidation = OwnershipValidation.validateRequiredFields(
            type: selectedType,
            cost: cost
        )
        if !requiredFieldsValidation.isValid {
            errorMessage = requiredFieldsValidation.message ?? "Missing required fields"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate metrics
        let metricsValidations = OwnershipValidation.validateMetrics(
            mileage: mileage,
            hours: hours,
            cost: cost
        )
        if !metricsValidations.isEmpty {
            errorMessage = metricsValidations[0].message ?? "Invalid metrics"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // All validations passed, create and save the record
        let record = OwnershipRecord(
            type: selectedType,
            date: date,
            details: details.trimmingCharacters(in: .whitespaces),
            mileage: VehicleValidation.parseAndRoundDecimal(mileage),
            distanceUnit: distanceUnit,
            hours: VehicleValidation.parseAndRoundDecimal(hours),
            cost: VehicleValidation.parseAndRoundDecimal(cost),
            currencyCode: currencyCode
        )
        
        vehicle.ownershipRecords?.append(record)
        modelContext.insert(record)
        
        HapticManager.standardSuccess()
        logger.info("Ownership record added successfully", category: .database)
        dismiss()
    }
}

// MARK: - Supporting Views
private struct OwnershipDetailsSection: View, Equatable {
    let vehicles: [Vehicle]
    @Binding var selectedVehicle: Vehicle?
    @Binding var date: Date
    @Binding var selectedType: OwnershipEventType
    @Binding var details: String
    @FocusState.Binding var focusedField: FormField?
    
    var body: some View {
        Section {
            VehiclePicker(vehicles: vehicles, selectedVehicle: $selectedVehicle)
                .accessibilityLabel("Vehicle selection")
                .accessibilityHint("Select a vehicle for this ownership record")
                .frame(height: 38)
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .accessibilityLabel("Record date")
                .accessibilityHint("Select the date of this ownership event")
                .frame(height: 38)
            
            TypePicker(selectedType: $selectedType)
                .frame(height: 38)
            
            GuidanceView(type: selectedType)
            
            VStack(alignment: .leading) {
                Text("Details*")
                    .font(.callout)
                TextEditor(text: $details)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .accessibilityLabel("Record details")
                    .accessibilityHint("Enter the details of this ownership record")
            }
        } header: {
            Text("RECORD DETAILS")
                .textCase(.uppercase)
                .font(.subheadline)
        } footer: {
            Text("* Required")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(nil)
        }
    }
    
    static func == (lhs: OwnershipDetailsSection, rhs: OwnershipDetailsSection) -> Bool {
        lhs.vehicles == rhs.vehicles &&
        lhs.selectedVehicle?.id == rhs.selectedVehicle?.id &&
        lhs.date == rhs.date &&
        lhs.selectedType == rhs.selectedType &&
        lhs.details == rhs.details
    }
}

private struct TypePicker: View, Equatable {
    @Binding var selectedType: OwnershipEventType
    
    var body: some View {
        Picker("Type", selection: Binding(
            get: { selectedType },
            set: { 
                HapticManager.standardSelectionChanged()
                selectedType = $0 
            }
        )) {
            ForEach(OwnershipEventType.allTypes, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
        .accessibilityLabel("Record type")
        .accessibilityHint("Select the type of ownership record")
    }
    
    static func == (lhs: TypePicker, rhs: TypePicker) -> Bool {
        lhs.selectedType == rhs.selectedType
    }
}

private struct GuidanceView: View, Equatable {
    let type: OwnershipEventType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.guidance.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach(type.guidance.details, id: \.self) { detail in
                Text("• " + detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, 16)
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guidance for \(type.displayName)")
    }
    
    static func == (lhs: GuidanceView, rhs: GuidanceView) -> Bool {
        lhs.type == rhs.type
    }
} 