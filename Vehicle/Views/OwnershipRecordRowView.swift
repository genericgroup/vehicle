import SwiftUI
import SwiftData

struct OwnershipRecordTypePicker: View {
    @Bindable var record: OwnershipRecord
    
    var body: some View {
        Picker("Type", selection: $record.type) {
            ForEach(OwnershipEventType.allTypes, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
    }
}

struct OwnershipRecordDetailsField: View {
    @Bindable var record: OwnershipRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Details")
                .font(.callout)
            TextEditor(text: Binding(
                get: { record.details ?? "" },
                set: { record.details = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct OwnershipRecordDetailsSection: View {
    @Bindable var record: OwnershipRecord
    @Query(sort: [
        SortDescriptor(\Vehicle.year, order: .reverse),
        SortDescriptor(\Vehicle.make),
        SortDescriptor(\Vehicle.model)
    ]) private var vehicles: [Vehicle]
    
    var body: some View {
        Section("RECORD DETAILS") {
            Picker("Vehicle", selection: Binding(
                get: { record.vehicle },
                set: { record.vehicle = $0 }
            )) {
                ForEach(vehicles) { vehicle in
                    Text(vehicle.displayName).tag(vehicle as Vehicle?)
                }
            }
            .frame(height: 38)
            
            DatePicker("Date", selection: $record.date, displayedComponents: .date)
                .frame(height: 38)
            
            OwnershipRecordTypePicker(record: record)
                .frame(height: 38)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(record.type.guidance.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(record.type.guidance.details, id: \.self) { detail in
                    Text("• " + detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .padding(.leading, 16)
            .listRowSeparator(.hidden)
            
            OwnershipRecordDetailsField(record: record)
        }
    }
}

struct OwnershipRecordMetricsSection: View {
    @Bindable var record: OwnershipRecord
    private let currencyCodes = Locale.commonISOCurrencyCodes
    
    var body: some View {
        Section("METRICS") {
            HStack {
                TextField("Mileage", text: Binding(
                    get: { record.mileage.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                    set: { record.mileage = VehicleValidation.parseAndRoundDecimal($0) }
                ))
                .keyboardType(.decimalPad)
                
                Picker("", selection: Binding(
                    get: { DistanceUnit(rawValue: record.distanceUnit) ?? .miles },
                    set: { record.distanceUnit = $0.rawValue }
                )) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .labelsHidden()
            }
            .frame(height: 38)
            
            TextField("Hours", text: Binding(
                get: { record.hours.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                set: { record.hours = VehicleValidation.parseAndRoundDecimal($0) }
            ))
            .keyboardType(.decimalPad)
            .frame(height: 38)
            
            HStack {
                TextField("Cost", text: Binding(
                    get: { record.cost.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                    set: { record.cost = VehicleValidation.parseAndRoundDecimal($0) }
                ))
                .keyboardType(.decimalPad)
                
                Picker("", selection: $record.currencyCode) {
                    ForEach(currencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .labelsHidden()
            }
            .frame(height: 38)
        }
    }
}

struct EditOwnershipRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var record: OwnershipRecord
    @Query(sort: [
        SortDescriptor(\Vehicle.year, order: .reverse),
        SortDescriptor(\Vehicle.make),
        SortDescriptor(\Vehicle.model)
    ]) private var vehicles: [Vehicle]
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    @FocusState private var focusedField: FormField?
    
    private let logger = AppLogger.shared
    private let currencyCodes = Locale.commonISOCurrencyCodes
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Vehicle*", selection: Binding(
                        get: { record.vehicle },
                        set: { 
                            HapticManager.shared.selectionChanged()
                            record.vehicle = $0 
                        }
                    )) {
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }
                    .frame(height: ViewConstants.rowHeight)
                    .accessibilityLabel("Vehicle selection")
                    .accessibilityHint("Select a vehicle for this record")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    DatePicker("Date", selection: $record.date, displayedComponents: .date)
                        .frame(height: ViewConstants.rowHeight)
                        .accessibilityLabel("Record date")
                        .accessibilityHint("Select the date of this ownership event")
                        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    Picker("Type", selection: Binding(
                        get: { record.type },
                        set: { 
                            HapticManager.shared.selectionChanged()
                            record.type = $0 
                        }
                    )) {
                        ForEach(OwnershipEventType.allTypes, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .frame(height: ViewConstants.rowHeight)
                    .accessibilityLabel("Record type")
                    .accessibilityHint("Select the type of ownership record")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    VStack(alignment: .leading, spacing: ViewConstants.defaultSpacing) {
                        Text(record.type.guidance.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(record.type.guidance.details, id: \.self) { detail in
                            Text("• " + detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, ViewConstants.defaultSpacing)
                    .padding(.leading, ViewConstants.defaultSpacing)
                    .listRowSeparator(.hidden)
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    .accessibilityLabel("Record type guidance")
                    
                    VStack(alignment: .leading) {
                        Text("Details*")
                            .font(.callout)
                            .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                        TextEditor(text: Binding(
                            get: { record.details ?? "" },
                            set: { record.details = $0.isEmpty ? nil : $0 }
                        ))
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
                        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                } footer: {
                    Text("* Required")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                        .textCase(nil)
                }
                
                MetricsFormView(
                    mileage: Binding(
                        get: { record.mileage.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                        set: { record.mileage = VehicleValidation.parseAndRoundDecimal($0) }
                    ),
                    distanceUnit: Binding(
                        get: { DistanceUnit(rawValue: record.distanceUnit) ?? .miles },
                        set: { record.distanceUnit = $0.rawValue }
                    ),
                    hours: Binding(
                        get: { record.hours.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                        set: { record.hours = VehicleValidation.parseAndRoundDecimal($0) }
                    ),
                    cost: Binding(
                        get: { record.cost.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                        set: { record.cost = VehicleValidation.parseAndRoundDecimal($0) }
                    ),
                    currencyCode: $record.currencyCode,
                    currencyCodes: currencyCodes,
                    focusedField: $focusedField
                )
                
                Section {
                    Button(role: .destructive) {
                        HapticManager.shared.impact(style: .medium)
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Record", systemImage: "trash.fill")
                    }
                    .accessibilityLabel("Delete record")
                    .accessibilityHint("Permanently remove this ownership record")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                }
            }
            .navigationTitle("Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing")
                    .accessibilityHint("Discard changes and return to the previous screen")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.impact(style: .light)
                        validateAndSave()
                    }
                    .accessibilityLabel("Save changes")
                    .accessibilityHint("Validate and save your changes to this record")
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            HapticManager.shared.impact(style: .light)
                            focusedField = nil
                        }
                        .accessibilityLabel("Dismiss keyboard")
                    }
                }
            }
            .alert("Delete Record?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteRecord()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this record? This action cannot be undone.")
            }
            .alert("Validation Error", isPresented: $showingError) {
                Button("OK") {
                    HapticManager.shared.impact(style: .light)
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
    
    private func validateAndSave() {
        // Validate vehicle selection
        if record.vehicle == nil {
            errorMessage = "Please select a vehicle"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate date
        let dateValidation = OwnershipValidation.validateDate(record.date)
        if !dateValidation.isValid {
            errorMessage = dateValidation.message ?? "Invalid date"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate details
        let detailsValidation = OwnershipValidation.validateDetails(record.details ?? "", type: record.type)
        if !detailsValidation.isValid {
            errorMessage = detailsValidation.message ?? "Invalid details"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate required fields based on type
        let requiredFieldsValidation = OwnershipValidation.validateRequiredFields(type: record.type, cost: record.cost?.description ?? "")
        if !requiredFieldsValidation.isValid {
            errorMessage = requiredFieldsValidation.message ?? "Missing required fields"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate metrics
        let metricsValidations = OwnershipValidation.validateMetrics(
            mileage: record.mileage.map { "\($0)" } ?? "",
            hours: record.hours.map { "\($0)" } ?? "",
            cost: record.cost.map { "\($0)" } ?? ""
        )
        if !metricsValidations.isEmpty {
            errorMessage = metricsValidations[0].message ?? "Invalid metrics"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // All validations passed
        HapticManager.shared.notifySuccess()
        logger.info("Ownership record updated successfully", category: .database)
        dismiss()
    }
    
    private func deleteRecord() {
        if let vehicle = record.vehicle {
            vehicle.ownershipRecords?.removeAll { $0.id == record.id }
        }
        modelContext.delete(record)
        logger.info("Ownership record deleted", category: .database)
        dismiss()
    }
}

struct OwnershipRecordRowView: View {
    let record: OwnershipRecord
    let allRecords: [OwnershipRecord]
    @State private var showingEditSheet = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Formatting Properties
    private var formattedDate: String {
        record.date.standardFormattedNumeric
    }
    
    private var formattedMileage: String? {
        guard let mileage = record.mileage else { return nil }
        let unit = DistanceUnit(rawValue: record.distanceUnit) ?? .miles
        return formatDecimalWithUnit(mileage, unit: unit.shortLabel)
    }
    
    private var formattedHours: String? {
        guard let hours = record.hours else { return nil }
        return formatDecimalWithUnit(hours, unit: "hrs")
    }
    
    private var formattedCost: String? {
        guard let cost = record.cost else { return nil }
        return cost.formatted(.currency(code: record.currencyCode).precision(.fractionLength(2)))
    }
    
    // MARK: - Layout Properties
    private var leftColumnWidth: CGFloat {
        let dateWidth = calculateMaxDateWidth()
        let metricsWidth = calculateMaxMetricsWidth()
        return max(dateWidth, metricsWidth) + 24 // Add padding
    }
    
    // MARK: - Helper Functions
    private func formatDecimalWithUnit(_ value: Decimal, unit: String) -> String {
        NumberFormatters.formatDecimalWithUnit(value, unit: unit)
    }
    
    private func calculateMaxDateWidth() -> CGFloat {
        let font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        return allRecords.map { record in
            record.date.standardFormattedNumeric.size(withAttributes: attributes).width
        }.max() ?? 0
    }
    
    private func calculateMaxMetricsWidth() -> CGFloat {
        let font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        return allRecords.compactMap { record -> CGFloat in
            if let mileage = record.mileage {
                let unit = DistanceUnit(rawValue: record.distanceUnit) ?? .miles
                let mileageStr = formatDecimalWithUnit(mileage, unit: unit.shortLabel)
                return mileageStr.size(withAttributes: attributes).width
            } else if let hours = record.hours {
                let hoursStr = formatDecimalWithUnit(hours, unit: "hrs")
                return hoursStr.size(withAttributes: attributes).width
            }
            return 0
        }.max() ?? 0
    }
    
    // MARK: - View Components
    private var dateAndMetricsColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            if let mileage = formattedMileage {
                Text(mileage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            } else if let hours = formattedHours {
                Text(hours)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(width: leftColumnWidth, alignment: .leading)
    }
    
    private var detailsColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.type.displayName)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            if let details = record.details, !details.isEmpty {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .layoutPriority(1)
    }
    
    private var costColumn: some View {
        Group {
            if horizontalSizeClass == .regular, let cost = formattedCost {
                Text(cost)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(alignment: .trailing)
            }
        }
    }
    
    var body: some View {
        Button {
            showingEditSheet = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                dateAndMetricsColumn
                detailsColumn
                Spacer()
                costColumn
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingEditSheet) {
            EditOwnershipRecordView(record: record)
        }
    }
} 