import SwiftUI

extension View {
    func standardDynamicTypeSize() -> some View {
        self.dynamicTypeSize(ViewConstants.dynamicTypeRange)
    }
    
    func standardKeyboardDoneButton(focusedField: FocusState<FormField?>.Binding) -> some View {
        toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        HapticManager.shared.impact(style: .light)
                        focusedField.wrappedValue = nil
                    }
                    .accessibilityLabel("Dismiss keyboard")
                }
            }
        }
    }
    
    func standardDeleteButton(title: String, action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            HapticManager.shared.impact(style: .medium)
            action()
        } label: {
            Label(title, systemImage: "trash.fill")
        }
        .accessibilityLabel(title)
        .accessibilityHint("Permanently remove this item")
        .standardDynamicTypeSize()
    }
    
    func standardFormStyle() -> some View {
        self
            .formStyle(.grouped)
            .standardDynamicTypeSize()
    }
    
    func standardNavigationBar(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Standard haptic feedback patterns
extension HapticManager {
    static func standardButtonTap() {
        shared.impact(style: .light)
    }
    
    static func standardSelectionChanged() {
        shared.selectionChanged()
    }
    
    static func standardDelete() {
        shared.impact(style: .medium)
    }
    
    static func standardError() {
        shared.notifyError()
    }
    
    static func standardSuccess() {
        shared.notifySuccess()
    }
    
    static func standardWarning() {
        shared.notifyWarning()
    }
} 