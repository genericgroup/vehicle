import SwiftUI
import SwiftData

struct NotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var notes: String
    @State private var localNotes: String
    @State private var showingValidationError = false
    @State private var validationError: String?
    
    init(notes: Binding<String>) {
        self._notes = notes
        self._localNotes = State(initialValue: notes.wrappedValue)
    }
    
    private let logger = AppLogger.shared
    
    private func saveChanges() {
        let validation = VehicleValidation.validateNotes(localNotes)
        if validation.isValid {
            notes = localNotes.trimmingCharacters(in: .whitespaces)
            do {
                try modelContext.save()
                logger.info("Manually saved notes", category: .database)
                dismiss()
            } catch {
                logger.error("Failed to save notes: \(error.localizedDescription)", category: .database)
            }
        } else {
            validationError = validation.message
            showingValidationError = true
        }
    }
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $localNotes)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .navigationTitle("Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            // Discard changes - localNotes is not saved to binding
                            HapticManager.standardButtonTap()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveChanges()
                        }
                    }
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .top) {
                    Divider()
                        .background(.separator)
                }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK") {
                    showingValidationError = false
                }
            } message: {
                Text(validationError ?? "Invalid input")
            }
        }
    }
} 