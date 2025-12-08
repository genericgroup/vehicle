import SwiftUI

struct VehicleRowView: View {
    let vehicle: Vehicle
    let isSelected: Bool
    @AppStorage("vehicleGroupOption") private var groupOption = VehicleGroupOption.none.rawValue
    @AppStorage("showNicknamesInList") private var showNicknamesInList = true
    @AppStorage("showIconsInList") private var showIconsInList = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentGroupOption: VehicleGroupOption {
        VehicleGroupOption(rawValue: groupOption) ?? .none
    }
    
    private var displayName: String {
        VehicleDisplayHelper.vehicleDisplayName(vehicle, inGroup: currentGroupOption)
    }
    
    private var secondaryText: String? {
        VehicleDisplayHelper.vehicleSecondaryText(vehicle, inGroup: currentGroupOption)
    }
    
    private var primaryTextStyle: some ShapeStyle {
        Color(isSelected ? (colorScheme == .light ? .black : .white) : .label)
    }
    
    private var secondaryTextStyle: some ShapeStyle {
        if isSelected {
            let baseColor = colorScheme == .light ? Color(.black) : Color(.white)
            return baseColor.opacity(0.85)
        }
        return Color(.secondaryLabel)
    }
    
    private var tertiaryTextStyle: some ShapeStyle {
        if isSelected {
            let baseColor = colorScheme == .light ? Color(.black) : Color(.white)
            return baseColor.opacity(0.7)
        }
        return Color(.tertiaryLabel)
    }
    
    private var pinStyle: some ShapeStyle {
        Color(isSelected ? (colorScheme == .light ? .black : .white) : .tintColor)
    }
    
    private func buildPrimaryText() -> String {
        var text = ""
        if currentGroupOption != .year {
            text += String(vehicle.year) + " "
        }
        if currentGroupOption != .make {
            text += vehicle.make + " "
        }
        text += vehicle.model
        return text
    }
    
    // MARK: - Subviews
    private var vehicleIcon: some View {
        Group {
            if showIconsInList && !vehicle.icon.isEmpty {
                Text(vehicle.icon)
                    .font(.system(.title2, design: .default))
                    .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                    .frame(minWidth: 28, maxWidth: 32, alignment: .center)
                    .contentShape(Rectangle())
            }
        }
    }
    
    private var primaryInfo: some View {
        Text(buildPrimaryText())
            .font(.system(.title3, design: .default))
            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
            .foregroundStyle(primaryTextStyle)
            .lineLimit(2)
    }
    
    private var pinIcon: some View {
        Group {
            if vehicle.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(pinStyle)
                    .font(.caption)
            }
        }
    }
    
    private var categoryText: some View {
        Text(vehicle.category.displayName)
            .font(.caption)
            .foregroundStyle(secondaryTextStyle)
    }
    
    private var separatorText: some View {
        Text(" > ")
            .font(.caption)
            .foregroundStyle(tertiaryTextStyle)
    }
    
    private var subcategoryText: some View {
        Text(vehicle.subcategory?.displayName ?? "")
            .font(.caption)
            .foregroundStyle(secondaryTextStyle)
            .lineLimit(1)
    }
    
    private var categoryInfo: some View {
        Group {
            if horizontalSizeClass == .regular {
                if let _ = vehicle.subcategory {
                    HStack(spacing: 0) {
                        categoryText
                        separatorText
                        subcategoryText
                    }
                } else {
                    categoryText
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var secondaryInfo: some View {
        HStack(alignment: .center, spacing: 4) {
            if showNicknamesInList, let nickname = vehicle.nickname {
                Text(nickname)
                    .font(.system(.subheadline, design: .default))
                    .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                    .foregroundStyle(secondaryTextStyle)
                    .lineLimit(1)
            }
            
            if showNicknamesInList && vehicle.nickname != nil && horizontalSizeClass == .regular && vehicle.subcategory != nil {
                Text("•")
                    .font(.caption2)
                    .foregroundStyle(tertiaryTextStyle)
            }
            
            categoryInfo
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            vehicleIcon
            
            VStack(alignment: .leading, spacing: 2) {
                primaryInfo
                secondaryInfo
            }
            
            Spacer(minLength: 0)
            
            pinIcon  // Pin icon now at the far right
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(secondaryText ?? "")
    }
    
    private func buildAccessibilityLabel() -> String {
        var components: [String] = []
        
        // Add pin status if pinned
        if vehicle.isPinned {
            components.append("Pinned")
        }
        
        // Add main display name
        components.append(displayName)
        
        // Add secondary text if available
        if let secondary = secondaryText {
            components.append(secondary)
        }
        
        // Add icon if present and enabled
        if showIconsInList && !vehicle.icon.isEmpty {
            components.append(vehicle.icon)
        }
        
        // Join all components with commas
        return components.joined(separator: ", ")
    }
} 