import SwiftUI

struct MenuItemView: View {
    let colorName: String
    let color: Color
    private let logger = AppLogger.shared
    
    var body: some View {
        HStack {
            Text(colorName)
                .foregroundStyle(.primary)
            Spacer()
            if colorName != "Custom" {
                Image(systemName: "circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(color, color.opacity(0.3))
                    .font(.system(size: 14))
            }
        }
        .frame(minWidth: 100, alignment: .leading)
        .contentShape(Rectangle())
        .onAppear {
            logger.debug("MenuItemView appeared for color: \(colorName)", category: .userInterface)
        }
    }
} 