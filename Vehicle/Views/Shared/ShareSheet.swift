import SwiftUI

/// A UIKit share sheet wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let filename: String
    private let logger = AppLogger.shared
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Add cleanup handler if needed
        if let url = activityItems.first as? URL {
            controller.completionWithItemsHandler = { _, _, _, _ in
                DispatchQueue.global(qos: .utility).async {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
