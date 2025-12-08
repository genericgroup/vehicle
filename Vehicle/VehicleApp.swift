//
//  VehicleApp.swift
//  Vehicle
//
//  Created by Andy Carlson on 1/20/25.
//

import SwiftUI
import SwiftData

// Define notification name constants
extension Notification.Name {
    static let showAddVehicle = Notification.Name("ShowAddVehicle")
    static let showAddEvent = Notification.Name("ShowAddEvent")
    static let showAddOwnership = Notification.Name("ShowAddOwnership")
    static let showSettings = Notification.Name("ShowSettings")
}

enum QuickAction: String {
    case addVehicle = "AddVehicle"
    case addEvent = "AddEvent"
    case addOwnership = "AddOwnership"
}

@main
struct VehicleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let logger = AppLogger.shared
    private let modelContainer: ModelContainer
    
    init() {
        logger.info("Initializing VehicleApp", category: .userInterface)
        
        // Configure model container with migration plan
        do {
            let schema = Schema(versionedSchema: VehicleSchemaV1.self)
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("--uitesting")
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: VehicleMigrationPlan.self,
                configurations: [configuration]
            )
            
            logger.info("Successfully configured ModelContainer with migration plan", category: .database)
            logger.info("Current schema version: \(SchemaVersionManager.currentSchemaVersion)", category: .database)
            
            if let storedVersion = SchemaVersionManager.storedSchemaVersion {
                logger.info("Stored schema version: \(storedVersion)", category: .database)
            } else {
                logger.info("No stored schema version - first launch", category: .database)
            }
        } catch {
            logger.critical("Failed to configure ModelContainer: \(error.localizedDescription)", category: .database)
            
            // Log additional error details
            let nsError = error as NSError
            logger.error("Error domain: \(nsError.domain)", category: .database)
            logger.error("Error code: \(nsError.code)", category: .database)
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                logger.error("Underlying error: \(underlyingError)", category: .database)
            }
            
            // Create a fallback in-memory container
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MigrationAwareContentView()
        }
        .windowResizability(.automatic)
        .defaultSize(width: 1000, height: 700)
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Settings") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Migration Aware Content View

struct MigrationAwareContentView: View {
    @StateObject private var migrationCoordinator = MigrationCoordinator()
    @State private var hasStartedMigrationCheck = false
    
    var body: some View {
        Group {
            switch migrationCoordinator.migrationState {
            case .idle, .checkingVersion:
                MigrationProgressView(
                    state: migrationCoordinator.migrationState,
                    progress: migrationCoordinator.migrationProgress
                )
                .task {
                    if !hasStartedMigrationCheck {
                        hasStartedMigrationCheck = true
                        await migrationCoordinator.performMigrationIfNeeded()
                    }
                }
                
            case .creatingBackup, .migrating, .verifying:
                MigrationProgressView(
                    state: migrationCoordinator.migrationState,
                    progress: migrationCoordinator.migrationProgress
                )
                
            case .completed:
                ContentView()
                
            case .failed:
                MigrationErrorView(
                    error: migrationCoordinator.migrationError,
                    onRetry: {
                        Task {
                            await migrationCoordinator.retryMigration()
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Migration Progress View

struct MigrationProgressView: View {
    let state: MigrationCoordinator.MigrationState
    let progress: Double
    
    private var statusText: String {
        switch state {
        case .idle:
            return "Preparing..."
        case .checkingVersion:
            return "Checking data version..."
        case .creatingBackup:
            return "Creating backup..."
        case .migrating:
            return "Updating data..."
        case .verifying:
            return "Verifying..."
        case .completed:
            return "Complete!"
        case .failed:
            return "Failed"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Vehicle")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Migration Error View

struct MigrationErrorView: View {
    let error: MigrationError?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Migration Error")
                .font(.title)
                .fontWeight(.bold)
            
            if let error = error {
                VStack(spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: onRetry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = AppLogger.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Log all available quick actions
        logger.info("Available Quick Actions: \(UIApplication.shared.shortcutItems ?? [])", category: .userInterface)
        
        // Only handle quick action if app was launched from one
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            logger.info("App launched from quick action: \(shortcutItem.type)", category: .userInterface)
            return handleQuickAction(shortcutItem)
        }
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Log scene connection details
        logger.info("Configuring scene with role: \(connectingSceneSession.role.rawValue)", category: .userInterface)
        if let shortcutItem = options.shortcutItem {
            logger.info("Scene connected with quick action: \(shortcutItem.type)", category: .userInterface)
        }
        
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    private func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(rawValue: shortcutItem.type) else {
            logger.error("Invalid quick action type: \(shortcutItem.type)", category: .userInterface)
            return false
        }
        
        logger.info("Handling quick action during app launch: \(action)", category: .userInterface)
        
        // Use a longer delay to ensure the app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
        return true
    }
}
