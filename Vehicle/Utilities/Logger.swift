import Foundation
import OSLog

enum LogCategory: String, CaseIterable {
    case modelData = "ModelData"
    case userInterface = "UI"
    case fileSystem = "FileSystem"
    case database = "Database"
    case general = "General"
    case initialization = "Initialization"
    case state = "State"
    case network = "Network"
    case sync = "Sync"
    case security = "Security"
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

@Observable
final class AppLogger {
    static let shared = AppLogger()
    private let logger: Logger
    private let isDebugBuild: Bool
    
    #if DEBUG
    private var enabledCategories: Set<LogCategory> = Set(LogCategory.allCases)
    private var minimumLogLevel: LogLevel = .debug
    #else
    private var enabledCategories: Set<LogCategory> = [.database, .fileSystem, .general]
    private var minimumLogLevel: LogLevel = .info
    #endif
    
    private init() {
        #if DEBUG
        self.isDebugBuild = true
        #else
        self.isDebugBuild = false
        #endif
        
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "net.genericgroup.Vehicle",
            category: "VehicleApp"
        )
    }
    
    private func shouldLog(level: LogLevel, category: LogCategory) -> Bool {
        guard enabledCategories.contains(category) else { return false }
        
        let logLevels: [LogLevel] = [.debug, .info, .warning, .error, .critical]
        guard let minimumIndex = logLevels.firstIndex(of: minimumLogLevel),
              let currentIndex = logLevels.firstIndex(of: level) else {
            return false
        }
        
        return currentIndex >= minimumIndex
    }
    
    func log(_ message: String, category: LogCategory = .general, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard shouldLog(level: level, category: category) else { return }
        
        let sourceInfo = isDebugBuild ? "| \(URL(fileURLWithPath: file).lastPathComponent):\(line) - \(function)" : ""
        let formattedMessage = "[\(category.rawValue)][\(level.rawValue)] \(message) \(sourceInfo)"
        
        switch level {
        case .debug:
            logger.debug("\(formattedMessage)")
        case .info:
            logger.info("\(formattedMessage)")
        case .warning:
            logger.warning("\(formattedMessage)")
        case .error:
            logger.error("\(formattedMessage)")
        case .critical:
            logger.critical("\(formattedMessage)")
        }
    }
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .critical, file: file, function: function, line: line)
    }
    
    // MARK: - Runtime Configuration
    
    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }
    
    func enableCategory(_ category: LogCategory) {
        enabledCategories.insert(category)
    }
    
    func disableCategory(_ category: LogCategory) {
        enabledCategories.remove(category)
    }
    
    func enableAllCategories() {
        enabledCategories = Set(LogCategory.allCases)
    }
    
    func disableAllCategories() {
        enabledCategories.removeAll()
    }
} 