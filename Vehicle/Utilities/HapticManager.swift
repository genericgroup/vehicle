import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    // Reusable generators - prepared once for lower latency
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    private init() {
        // Prepare generators for immediate use
        prepareGenerators()
    }
    
    /// Prepare all generators for lower latency on first use
    func prepareGenerators() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
    }
    
    // Light impact for selection feedback
    func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare() // Prepare for next use
    }
    
    // Success feedback
    func notifySuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    // Error feedback
    func notifyError() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // Warning feedback
    func notifyWarning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    // Impact feedback with different intensities
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            lightImpactGenerator.impactOccurred()
            lightImpactGenerator.prepare()
        case .medium:
            mediumImpactGenerator.impactOccurred()
            mediumImpactGenerator.prepare()
        case .heavy:
            heavyImpactGenerator.impactOccurred()
            heavyImpactGenerator.prepare()
        case .soft:
            lightImpactGenerator.impactOccurred(intensity: 0.5)
            lightImpactGenerator.prepare()
        case .rigid:
            heavyImpactGenerator.impactOccurred(intensity: 0.8)
            heavyImpactGenerator.prepare()
        @unknown default:
            mediumImpactGenerator.impactOccurred()
            mediumImpactGenerator.prepare()
        }
    }
} 