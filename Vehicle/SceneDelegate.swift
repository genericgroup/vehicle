import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    // Note: SceneDelegate is instantiated by the system, not as a singleton.
    // The handleQuickAction closure is available for custom handling if needed.
    var handleQuickAction: ((QuickAction) -> Void)?
    
    private let logger = AppLogger.shared
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // Log current quick actions state
        logger.info("Current Quick Actions: \(UIApplication.shared.shortcutItems ?? [])", category: .userInterface)
        
        guard let action = QuickAction(rawValue: shortcutItem.type) else {
            logger.error("Invalid quick action type: \(shortcutItem.type)", category: .userInterface)
            completionHandler(false)
            return
        }
        
        logger.info("Handling quick action after app launch: \(action)", category: .userInterface)
        logger.info("Quick action details - Title: \(shortcutItem.localizedTitle), Type: \(shortcutItem.type)", category: .userInterface)
        
        // Post notification immediately on the main thread
        DispatchQueue.main.async {
            switch action {
            case .addVehicle:
                NotificationCenter.default.post(name: .showAddVehicle, object: nil)
                self.logger.info("Posted showAddVehicle notification", category: .userInterface)
            case .addEvent:
                NotificationCenter.default.post(name: .showAddEvent, object: nil)
                self.logger.info("Posted showAddEvent notification", category: .userInterface)
            case .addOwnership:
                NotificationCenter.default.post(name: .showAddOwnership, object: nil)
                self.logger.info("Posted showAddOwnership notification", category: .userInterface)
            }
        }
        
        completionHandler(true)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Log scene connection and quick actions
        logger.info("Scene will connect - Session role: \(session.role.rawValue)", category: .userInterface)
        logger.info("Available Quick Actions: \(UIApplication.shared.shortcutItems ?? [])", category: .userInterface)
        
        if let shortcutItem = connectionOptions.shortcutItem {
            logger.info("Scene connecting with quick action: \(shortcutItem.type)", category: .userInterface)
        }
    }
} 