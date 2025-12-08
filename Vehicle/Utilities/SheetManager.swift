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
        guard !isProcessing else {
            logger.debug("Ignoring sheet presentation - already processing", category: .userInterface)
            return
        }
        
        logger.debug("Processing sheet presentation request: \(String(describing: sheet))", category: .userInterface)
        isProcessing = true
        
        // Ensure we're on the main thread and add a slight delay
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            
            if activeSheet == nil {
                logger.debug("Presenting sheet: \(String(describing: sheet))", category: .userInterface)
                activeSheet = sheet
            } else {
                logger.debug("Cannot present sheet - another sheet is active", category: .userInterface)
            }
            
            try? await Task.sleep(for: .milliseconds(500))
            isProcessing = false
            logger.debug("Sheet presentation processing completed", category: .userInterface)
        }
    }
    
    func dismissActiveSheet() {
        logger.debug("Dismissing active sheet: \(String(describing: activeSheet))", category: .userInterface)
        activeSheet = nil
    }
} 