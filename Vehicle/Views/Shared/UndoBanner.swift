import SwiftUI

/// A banner that appears at the bottom of the screen to allow undoing an action
struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trash")
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.subheadline)
                .lineLimit(1)
            
            Spacer()
            
            Button("Undo") {
                HapticManager.standardButtonTap()
                onUndo()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            
            Button {
                HapticManager.standardButtonTap()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        UndoBanner(
            message: "Vehicle '2024 Toyota Camry' deleted",
            onUndo: {},
            onDismiss: {}
        )
    }
}
