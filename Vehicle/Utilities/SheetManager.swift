import SwiftUI

@MainActor
final class SheetManager: ObservableObject {
    @Published private(set) var activeSheet: Sheet?
    private var isProcessing = false
    private let logger: AppLogger
    
    enum Sheet: Identifiable, Equatable {
        case categorization
        case details
        case notes
        case attachments
        
        var id: Int {
            switch self {
            case .categorization: return 0
            case .details: return 1
            case .notes: return 2
            case .attachments: return 3
            }
        }
    }
    
    init(logger: AppLogger = AppLogger.shared) {
        self.logger = logger
    }
    
    var activeSheetBinding: Binding<Sheet?> {
        Binding(
            get: { self.activeSheet },
            set: { newValue in
                if newValue == nil {
                    self.dismissActiveSheet()
                }
            }
        )
    }
    
    func presentSheet(_ sheet: Sheet) {
        // Simple synchronous guard - no race condition possible since we're @MainActor
        guard !isProcessing && activeSheet == nil else {
            logger.debug("Ignoring sheet presentation - already processing or sheet active", category: .userInterface)
            return
        }
        
        logger.debug("Presenting sheet: \(String(describing: sheet))", category: .userInterface)
        isProcessing = true
        activeSheet = sheet
        
        // Reset processing flag after a delay to prevent rapid re-triggering
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isProcessing = false
            logger.debug("Sheet presentation cooldown completed", category: .userInterface)
        }
    }
    
    func dismissActiveSheet() {
        logger.debug("Dismissing active sheet: \(String(describing: activeSheet))", category: .userInterface)
        activeSheet = nil
    }
} 