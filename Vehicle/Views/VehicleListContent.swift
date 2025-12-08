import SwiftUI
import SwiftData

enum SearchResultItem: Hashable {
    case vehicle(Vehicle)
    case event(Event)
    case ownershipRecord(OwnershipRecord)
    
    var id: String {
        switch self {
        case .vehicle(let vehicle):
            return "vehicle-\(vehicle.id)"
        case .event(let event):
            return "event-\(event.id)"
        case .ownershipRecord(let record):
            return "record-\(record.id)"
        }
    }
    
    var vehicle: Vehicle? {
        switch self {
        case .vehicle(let vehicle): return vehicle
        case .event(let event): return event.vehicle
        case .ownershipRecord(let record): return record.vehicle
        }
    }
    
    var date: Date {
        switch self {
        case .vehicle(let vehicle): return vehicle.addedDate
        case .event(let event): return event.date
        case .ownershipRecord(let record): return record.date
        }
    }
    
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SearchResultRow: View {
    let item: SearchResultItem
    let isSelected: Bool
    @State private var showingEditSheet = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedVehicle: Vehicle?
    
    private var primaryTextStyle: some ShapeStyle {
        if isSelected {
            return colorScheme == .light ? Color(.black) : Color(.white)
        }
        return Color(.label)
    }
    
    private var secondaryTextStyle: some ShapeStyle {
        if isSelected {
            return (colorScheme == .light ? Color(.black) : Color(.white)).opacity(0.8)
        }
        return Color(.secondaryLabel)
    }
    
    private var accessibilityLabel: String {
        switch item {
        case .vehicle(let vehicle):
            var components: [String] = []
            if vehicle.isPinned {
                components.append("Pinned")
            }
            components.append("Vehicle: \(vehicle.displayName)")
            if let nickname = vehicle.nickname {
                components.append("Nickname: \(nickname)")
            }
            components.append("\(vehicle.category.displayName)")
            if let subcategory = vehicle.subcategory {
                components.append(subcategory.displayName)
            }
            return components.joined(separator: ", ")
            
        case .event(let event):
            var components: [String] = [
                "Event",
                event.vehicle?.displayName ?? "Unknown Vehicle",
                event.category.displayName,
                event.subcategory.displayName,
                "Date: \(event.date.standardFormattedLong)"
            ]
            if let details = event.details {
                components.append("Details: \(details)")
            }
            if let mileage = event.mileage {
                components.append("\(mileage.formatted()) \(DistanceUnit(rawValue: event.distanceUnit)?.shortLabel ?? "")")
            }
            if let hours = event.hours {
                components.append("\(hours) hours")
            }
            if let cost = event.cost {
                components.append("\(cost.formatted(.currency(code: event.currencyCode)))")
            }
            return components.joined(separator: ", ")
            
        case .ownershipRecord(let record):
            var components: [String] = [
                "Ownership Record",
                record.vehicle?.displayName ?? "Unknown Vehicle",
                record.type.displayName,
                "Date: \(record.date.formatted(date: .long, time: .omitted))"
            ]
            if let details = record.details {
                components.append("Details: \(details)")
            }
            if let mileage = record.mileage {
                components.append("\(mileage.formatted()) \(DistanceUnit(rawValue: record.distanceUnit)?.shortLabel ?? "")")
            }
            if let hours = record.hours {
                components.append("\(hours) hours")
            }
            if let cost = record.cost {
                components.append("\(cost.formatted(.currency(code: record.currencyCode)))")
            }
            return components.joined(separator: ", ")
        }
    }
    
    private var accessibilityHint: String {
        switch item {
        case .vehicle:
            return "Double tap to view vehicle details"
        case .event:
            return "Double tap to edit event"
        case .ownershipRecord:
            return "Double tap to edit ownership record"
        }
    }
    
    var body: some View {
        Button {
            switch item {
            case .vehicle(let vehicle):
                selectedVehicle = vehicle
            case .event, .ownershipRecord:
                showingEditSheet = true
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                // Left: Icon
                switch item {
                case .vehicle(let vehicle):
                    if !vehicle.icon.isEmpty {
                        Text(vehicle.icon)
                            .font(.title2)
                            .frame(width: 28)
                    }
                case .event:
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                case .ownershipRecord:
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                }
                
                // Middle: Content
                VStack(alignment: .leading, spacing: 2) {
                    switch item {
                    case .vehicle(let vehicle):
                        Text(vehicle.displayName)
                            .font(.headline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(primaryTextStyle)
                    case .event(let event):
                        Text(event.vehicle?.displayName ?? "Unknown Vehicle")
                            .font(.headline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(primaryTextStyle)
                        Text("\(event.category.displayName) > \(event.subcategory.displayName)")
                            .font(.subheadline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(secondaryTextStyle)
                        if let details = event.details {
                            Text(details)
                                .font(.caption)
                                .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                                .foregroundStyle(secondaryTextStyle)
                                .lineLimit(1)
                        }
                    case .ownershipRecord(let record):
                        Text(record.vehicle?.displayName ?? "Unknown Vehicle")
                            .font(.headline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(primaryTextStyle)
                        Text(record.type.displayName)
                            .font(.subheadline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(secondaryTextStyle)
                        if let details = record.details {
                            Text(details)
                                .font(.caption)
                                .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                                .foregroundStyle(secondaryTextStyle)
                                .lineLimit(1)
                        }
                    }
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                // Right: Date for events/records
                switch item {
                case .vehicle:
                    EmptyView()
                case .event, .ownershipRecord:
                    Text(item.date.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(secondaryTextStyle)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .sheet(isPresented: $showingEditSheet) {
            switch item {
            case .vehicle:
                EmptyView() // Vehicle details are shown in the detail pane
            case .event(let event):
                EditEventView(event: event)
            case .ownershipRecord(let record):
                EditOwnershipRecordView(record: record)
            }
        }
    }
}

struct VehicleListContent: View {
    @Binding var selectedVehicle: Vehicle?
    let vehicles: [Vehicle]
    let filteredVehicles: [Vehicle]
    let groupedVehicles: [(String, [Vehicle])]
    let searchResults: [SearchResultItem]
    let viewModel: ContentViewModel
    let modelContext: ModelContext
    let logger: AppLogger
    @AppStorage("vehicleGroupOption") private var groupOption = VehicleGroupOption.none.rawValue
    @AppStorage("showNicknamesInList") private var showNicknamesInList = true
    @AppStorage("showIconsInList") private var showIconsInList = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentGroupOption: VehicleGroupOption {
        VehicleGroupOption(rawValue: groupOption) ?? .none
    }
    
    var body: some View {
        Group {
            if !searchResults.isEmpty {
                // Search results including events and ownership records
                ForEach(searchResults, id: \.id) { item in
                    SearchResultRow(
                        item: item, 
                        isSelected: selectedVehicle?.id == item.vehicle?.id,
                        selectedVehicle: $selectedVehicle
                    )
                    .tag(item.vehicle)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading) {
                        if case .vehicle(let vehicle) = item {
                            pinButton(for: vehicle)
                        }
                    }
                }
            } else if currentGroupOption == .none {
                // Ungrouped vehicle list
                ForEach(filteredVehicles) { vehicle in
                    VehicleRowView(vehicle: vehicle, isSelected: selectedVehicle?.id == vehicle.id)
                        .tag(vehicle)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading) {
                            pinButton(for: vehicle)
                        }
                }
            } else {
                // Grouped vehicle list
                ForEach(groupedVehicles, id: \.0) { section in
                    Section {
                        ForEach(section.1) { vehicle in
                            VehicleRowView(vehicle: vehicle, isSelected: selectedVehicle?.id == vehicle.id)
                                .tag(vehicle)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .leading) {
                                    pinButton(for: vehicle)
                                }
                        }
                    } header: {
                        Text(section.0)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    private func pinButton(for vehicle: Vehicle) -> some View {
        Button {
            viewModel.triggerPinHaptic()
            vehicle.isPinned.toggle()
            logger.info("\(vehicle.isPinned ? "Pinned" : "Unpinned") vehicle: \(vehicle.year) \(vehicle.make) \(vehicle.model)", category: .userInterface)
        } label: {
            Label(vehicle.isPinned ? "Unpin" : "Pin",
                  systemImage: vehicle.isPinned ? "pin.slash.fill" : "pin.fill")
        }
        .tint(.blue)
    }
} 