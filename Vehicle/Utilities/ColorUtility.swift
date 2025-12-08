import SwiftUI

/// Shared color utility functions
enum ColorUtility {
    /// Convert a color name string to a SwiftUI Color
    /// - Parameter name: The name of the color (case-insensitive)
    /// - Returns: The corresponding SwiftUI Color, or .clear if not found
    static func color(from name: String) -> Color {
        switch name.lowercased() {
        case "black": return .black
        case "white": return .white
        case "gray", "grey": return .gray
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "brown": return .brown
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "burgundy": return Color(red: 0.5, green: 0.0, blue: 0.13)
        case "navy": return Color(red: 0.0, green: 0.0, blue: 0.5)
        case "silver": return Color(red: 0.75, green: 0.75, blue: 0.75)
        case "gold": return Color(red: 0.83, green: 0.69, blue: 0.22)
        case "beige", "tan": return Color(red: 0.96, green: 0.96, blue: 0.86)
        case "maroon": return Color(red: 0.5, green: 0.0, blue: 0.0)
        case "teal": return .teal
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .clear
        }
    }
    
    /// Standard vehicle colors available for selection
    static let vehicleColors: [String] = [
        "Black",
        "White",
        "Gray",
        "Silver",
        "Red",
        "Blue",
        "Navy",
        "Green",
        "Brown",
        "Beige",
        "Orange",
        "Yellow",
        "Gold",
        "Purple",
        "Burgundy",
        "Maroon"
    ]
}
