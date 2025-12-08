import SwiftUI
import SwiftData

// MARK: - Main View
struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var event: Event
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
    
    private func validateAndSave() {
        guard let vehicle = event.vehicle else {
            errorMessage = "Please select a vehicle"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate date against vehicle year
        let dateValidation = VehicleValidation.validateEventDate(event.date, vehicleYear: vehicle.year)
        if !dateValidation.isValid {
            errorMessage = dateValidation.message ?? "Invalid date"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate details
        let detailsValidation = EventValidation.validateDetails(event.details ?? "")
        if !detailsValidation.isValid {
            errorMessage = detailsValidation.message ?? "Invalid details"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Type-specific validations based on category and subcategory
        let typeValidation = validateEventType()
        if !typeValidation.isValid {
            errorMessage = typeValidation.message ?? "Invalid event type configuration"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // Validate metrics
        let metricsValidations = EventValidation.validateMetrics(
            mileage: event.mileage.map { "\($0)" } ?? "",
            hours: event.hours.map { "\($0)" } ?? "",
            cost: event.cost.map { "\($0)" } ?? ""
        )
        if !metricsValidations.isEmpty {
            errorMessage = metricsValidations[0].message ?? "Invalid metrics"
            showingError = true
            HapticManager.shared.notifyError()
            return
        }
        
        // All validations passed
        HapticManager.shared.notifySuccess()
        logger.info("Event updated successfully", category: .database)
        dismiss()
    }
    
    private func validateEventType() -> ValidationResult {
        // Validate category and subcategory combination
        if !event.category.subcategories.contains(event.subcategory) {
            return ValidationResult(isValid: false, message: "Invalid event type combination")
        }
        
        return ValidationResult(isValid: true, message: nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Vehicle*", selection: Binding(
                        get: { event.vehicle },
                        set: { 
                            HapticManager.shared.selectionChanged()
                            event.vehicle = $0 
                        }
                    )) {
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }
                    .frame(height: ViewConstants.rowHeight)
                    .accessibilityLabel("Vehicle selection")
                    .accessibilityHint("Select a vehicle for this event")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    DatePicker("Date", selection: $event.date, displayedComponents: .date)
                        .frame(height: ViewConstants.rowHeight)
                        .accessibilityLabel("Event date")
                        .accessibilityHint("Select the date when this event occurred")
                        .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    Picker("Category", selection: Binding(
                        get: { event.category },
                        set: { 
                            HapticManager.shared.selectionChanged()
                            event.category = $0
                            // Reset subcategory if not valid for new category
                            if !$0.subcategories.contains(event.subcategory) {
                                event.subcategory = $0.subcategories[0]
                            }
                        }
                    )) {
                        ForEach(EventCategory.allCategories, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .frame(height: ViewConstants.rowHeight)
                    .accessibilityLabel("Event category")
                    .accessibilityHint("Select the general category of this event")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    Picker("Type", selection: Binding(
                        get: { event.subcategory },
                        set: { 
                            HapticManager.shared.selectionChanged()
                            event.subcategory = $0 
                        }
                    )) {
                        ForEach(event.category.subcategories, id: \.self) { subcategory in
                            Text(subcategory.displayName).tag(subcategory)
                        }
                    }
                    .frame(height: ViewConstants.rowHeight)
                    .accessibilityLabel("Event type")
                    .accessibilityHint("Select the specific type of event")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                    
                    Text(event.subcategory.guidance)
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
                        TextEditor(text: Binding(
                            get: { event.details ?? "" },
                            set: { event.details = $0.isEmpty ? nil : $0 }
                        ))
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
                
                MetricsFormView(
                    mileage: Binding(
                        get: { event.mileage.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                        set: { event.mileage = VehicleValidation.parseAndRoundDecimal($0) }
                    ),
                    distanceUnit: Binding(
                        get: { DistanceUnit(rawValue: event.distanceUnit) ?? .miles },
                        set: { event.distanceUnit = $0.rawValue }
                    ),
                    hours: Binding(
                        get: { event.hours.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                        set: { event.hours = VehicleValidation.parseAndRoundDecimal($0) }
                    ),
                    cost: Binding(
                        get: { event.cost.map { VehicleValidation.formatDecimalForDisplay($0) } ?? "" },
                        set: { event.cost = VehicleValidation.parseAndRoundDecimal($0) }
                    ),
                    currencyCode: $event.currencyCode,
                    currencyCodes: currencyCodes,
                    focusedField: $focusedField
                )
                
                Section {
                    Button(role: .destructive) {
                        HapticManager.shared.impact(style: .medium)
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Event", systemImage: "trash.fill")
                    }
                    .accessibilityLabel("Delete event")
                    .accessibilityHint("Permanently remove this event")
                    .dynamicTypeSize(ViewConstants.dynamicTypeRange)
                }
            }
            .navigationTitle("Edit Event")
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
                    .accessibilityHint("Validate and save your changes to this event")
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
            .alert("Delete Event?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteEvent()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
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
    
    private func deleteEvent() {
        if let vehicle = event.vehicle {
            vehicle.events?.removeAll { $0.id == event.id }
        }
        modelContext.delete(event)
        HapticManager.shared.notifySuccess()
        logger.info("Event deleted", category: .database)
        dismiss()
    }
}

struct EventRowView: View {
    let event: Event
    let allEvents: [Event]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingEditSheet = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var formattedDate: String {
        event.date.standardFormattedNumeric
    }
    
    private var formattedMileage: String? {
        guard let mileage = event.mileage else { return nil }
        let unit = DistanceUnit(rawValue: event.distanceUnit) ?? .miles
        return NumberFormatters.formatMileage(mileage, unit: unit)
    }
    
    private var formattedHours: String? {
        guard let hours = event.hours else { return nil }
        return NumberFormatters.formatHours(hours)
    }
    
    /// Use pre-calculated column width passed from parent, or calculate if not provided
    private var leftColumnWidth: CGFloat {
        // Use a reasonable default width that works for most cases
        // The parent section should pass a pre-calculated width for better performance
        return EventRowWidthCalculator.calculateWidth(for: allEvents)
    }
    
    var body: some View {
        Button {
            showingEditSheet = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                // Left side: Date & Mileage/Hours
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.caption2)
                        .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    if let mileage = formattedMileage {
                        Text(mileage)
                            .font(.caption2)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    } else if let hours = formattedHours {
                        Text(hours)
                            .font(.caption2)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(width: leftColumnWidth, alignment: .leading)
                
                // Middle: Event Category/Type & Details
                VStack(alignment: .leading, spacing: 2) {
                    if horizontalSizeClass == .regular {
                        Text("\(event.category.displayName) > \(event.subcategory.displayName)")
                            .font(.subheadline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    } else {
                        Text(event.subcategory.displayName)
                            .font(.subheadline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    if let details = event.details, !details.isEmpty {
                        Text(details)
                            .font(.caption)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .layoutPriority(1)
                
                Spacer()
                
                // Right side: Cost (if any) - only show on regular width screens
                if horizontalSizeClass == .regular, let cost = event.cost {
                    Text(cost, format: .currency(code: event.currencyCode)
                        .precision(.fractionLength(2)))
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(alignment: .trailing)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())  // Make entire row tappable
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)  // Ensure button fills entire width
        .sheet(isPresented: $showingEditSheet) {
            EditEventView(event: event)
        }
        .contentTransition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.category.id) on \(formattedDate)")
        .accessibilityValue(makeAccessibilityValue())
    }
    
    private func makeAccessibilityValue() -> String {
        var components: [String] = []
        
        if let details = event.details, !details.isEmpty {
            components.append(details)
        }
        
        if let mileage = formattedMileage {
            components.append("Mileage: \(mileage)")
        }
        
        if let hours = formattedHours {
            components.append("Hours: \(hours)")
        }
        
        return components.joined(separator: ", ")
    }
}

extension String {
    func size(withAttributes attributes: [NSAttributedString.Key: Any]) -> CGSize {
        return (self as NSString).size(withAttributes: attributes)
    }
}

// MARK: - Event Row Width Calculator

/// Utility for calculating and caching event row column widths
enum EventRowWidthCalculator {
    /// Cache for calculated widths keyed by event IDs hash
    private static var widthCache: [Int: CGFloat] = [:]
    private static let cacheLock = NSLock()
    private static let textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    ]
    
    /// Calculate the optimal left column width for a set of events
    /// Results are cached based on the events' IDs
    static func calculateWidth(for events: [Event]) -> CGFloat {
        guard !events.isEmpty else { return 80 } // Default minimum width
        
        // Generate cache key from event IDs
        let cacheKey = events.map { $0.id }.sorted().hashValue
        
        cacheLock.lock()
        if let cached = widthCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        
        // Calculate max width needed for date and metrics
        let dateWidth = events.map { event in
            event.date.standardFormattedNumeric.size(withAttributes: textAttributes).width
        }.max() ?? 0
        
        let metricsWidth = events.compactMap { event -> CGFloat in
            if let mileage = event.mileage {
                let unit = DistanceUnit(rawValue: event.distanceUnit) ?? .miles
                let mileageStr = NumberFormatters.formatMileage(mileage, unit: unit)
                return mileageStr.size(withAttributes: textAttributes).width
            } else if let hours = event.hours {
                let hoursStr = NumberFormatters.formatHours(hours)
                return hoursStr.size(withAttributes: textAttributes).width
            }
            return 0
        }.max() ?? 0
        
        // Add extra padding to ensure no truncation
        let width = max(dateWidth, metricsWidth) + 24
        
        // Cache the result
        cacheLock.lock()
        widthCache[cacheKey] = width
        // Limit cache size to prevent memory issues
        if widthCache.count > 100 {
            widthCache.removeAll()
            widthCache[cacheKey] = width
        }
        cacheLock.unlock()
        
        return width
    }
    
    /// Clear the width cache (call when events are modified)
    static func clearCache() {
        cacheLock.lock()
        widthCache.removeAll()
        cacheLock.unlock()
    }
} 