import SwiftUI
import SwiftData

// MARK: - Main View
struct AddEventView: View {
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
    @State private var selectedCategory = EventCategory.maintenance
    @State private var selectedSubcategory = EventCategory.maintenance.subcategories[0]
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
        _selectedSubcategory = State(initialValue: EventCategory.maintenance.subcategories[0])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                EventDetailsSection(
                    selectedVehicle: $selectedVehicle,
                    selectedCategory: $selectedCategory,
                    selectedSubcategory: $selectedSubcategory,
                    date: $date,
                    details: $details,
                    focusedField: $focusedField,
                    vehicles: vehicles
                )
                
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
            .standardNavigationBar(title: "Add Event")
            .standardFormStyle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.standardButtonTap()
                        logger.info("User cancelled adding event", category: .userInterface)
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discard this event and return to the previous screen")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        HapticManager.standardButtonTap()
                        addEvent()
                    }
                    .disabled(selectedVehicle == nil || details.isEmpty)
                    .accessibilityLabel("Add Event")
                    .accessibilityHint("Save this event")
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
        .onAppear {
            logger.debug("AddEventView appeared", category: .userInterface)
        }
    }
    
    private func addEvent() {
        // Validate vehicle selection
        guard let vehicle = selectedVehicle else {
            errorMessage = "Please select a vehicle"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate date against vehicle year
        let dateValidation = VehicleValidation.validateEventDate(date, vehicleYear: vehicle.year)
        if !dateValidation.isValid {
            errorMessage = dateValidation.message ?? "Invalid date"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate details
        let detailsValidation = EventValidation.validateDetails(details)
        if !detailsValidation.isValid {
            errorMessage = detailsValidation.message ?? "Invalid details"
            showingError = true
            HapticManager.standardError()
            return
        }
        
        // Validate metrics
        let metricsValidations = EventValidation.validateMetrics(
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
        
        // All validations passed, create and save the event
        let event = Event(
            category: selectedCategory,
            subcategory: selectedSubcategory,
            date: date,
            details: details.trimmingCharacters(in: .whitespaces),
            mileage: VehicleValidation.parseAndRoundDecimal(mileage),
            distanceUnit: distanceUnit,
            hours: VehicleValidation.parseAndRoundDecimal(hours),
            cost: VehicleValidation.parseAndRoundDecimal(cost),
            currencyCode: currencyCode
        )
        
        vehicle.events?.append(event)
        modelContext.insert(event)
        
        HapticManager.standardSuccess()
        logger.info("Event added successfully", category: .database)
        dismiss()
    }
}

// MARK: - Supporting Views
private struct VehiclePicker: View, Equatable {
    let vehicles: [Vehicle]
    @Binding var selectedVehicle: Vehicle?
    
    var body: some View {
        Picker("Vehicle*", selection: $selectedVehicle) {
            Text("Select Vehicle").tag(nil as Vehicle?)
            ForEach(vehicles) { vehicle in
                Text(vehicle.displayName).tag(vehicle as Vehicle?)
            }
        }
        .accessibilityLabel("Vehicle selection")
        .accessibilityHint("Select a vehicle for this event")
        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
    }
    
    static func == (lhs: VehiclePicker, rhs: VehiclePicker) -> Bool {
        lhs.vehicles == rhs.vehicles &&
        lhs.selectedVehicle?.id == rhs.selectedVehicle?.id
    }
}

private struct CategoryPicker: View, Equatable {
    @Binding var selectedCategory: EventCategory
    
    var body: some View {
        Picker("Category", selection: Binding(
            get: { selectedCategory },
            set: { 
                HapticManager.shared.selectionChanged()
                selectedCategory = $0 
            }
        )) {
            ForEach(EventCategory.allCategories, id: \.self) { category in
                Text(category.displayName).tag(category)
            }
        }
        .accessibilityLabel("Event category")
        .accessibilityHint("Select the general category of this event")
        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
    }
    
    static func == (lhs: CategoryPicker, rhs: CategoryPicker) -> Bool {
        lhs.selectedCategory == rhs.selectedCategory
    }
}

private struct SubcategoryPicker: View, Equatable {
    let selectedCategory: EventCategory
    @Binding var selectedSubcategory: EventSubcategory
    
    var body: some View {
        Picker("Type", selection: Binding(
            get: { selectedSubcategory },
            set: { 
                HapticManager.shared.selectionChanged()
                selectedSubcategory = $0 
            }
        )) {
            ForEach(selectedCategory.subcategories, id: \.self) { subcategory in
                Text(subcategory.displayName).tag(subcategory)
            }
        }
        .accessibilityLabel("Event type")
        .accessibilityHint("Select the specific type of event")
        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
    }
    
    static func == (lhs: SubcategoryPicker, rhs: SubcategoryPicker) -> Bool {
        lhs.selectedCategory == rhs.selectedCategory &&
        lhs.selectedSubcategory == rhs.selectedSubcategory
    }
}

private struct EventDetailsSection: View {
    @Binding var selectedVehicle: Vehicle?
    @Binding var selectedCategory: EventCategory
    @Binding var selectedSubcategory: EventSubcategory
    @Binding var date: Date
    @Binding var details: String
    @FocusState.Binding var focusedField: FormField?
    let vehicles: [Vehicle]
    
    var body: some View {
        Section {
            VehiclePicker(vehicles: vehicles, selectedVehicle: $selectedVehicle)
                .frame(height: ViewConstants.rowHeight)
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .frame(height: ViewConstants.rowHeight)
                .accessibilityLabel("Event date")
                .accessibilityHint("Select the date when this event occurred")
                .dynamicTypeSize(ViewConstants.dynamicTypeRange)
            
            CategoryPicker(selectedCategory: $selectedCategory)
                .frame(height: ViewConstants.rowHeight)
            
            SubcategoryPicker(selectedCategory: selectedCategory, selectedSubcategory: $selectedSubcategory)
                .frame(height: ViewConstants.rowHeight)
            
            Text(selectedSubcategory.guidance)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, ViewConstants.defaultSpacing)
                .padding(.leading, ViewConstants.defaultSpacing)
                .listRowSeparator(.hidden)
                .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                .accessibilityLabel("Event type guidance")
            
            VStack(alignment: .leading) {
                Text("Details*")
                    .font(.callout)
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                TextEditor(text: $details)
                    .frame(height: ViewConstants.textEditorHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .details)
                    .accessibilityLabel("Event details")
                    .accessibilityHint("Enter the details of what happened during this event")
            }
        } header: {
            Text("EVENT DETAILS")
                .textCase(.uppercase)
                .font(.subheadline)
                .dynamicTypeSize(ViewConstants.dynamicTypeRange)
        } footer: {
            Text("* Required")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                .textCase(nil)
        }
    }
} 