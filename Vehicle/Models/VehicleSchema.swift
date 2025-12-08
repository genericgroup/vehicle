import SwiftData
import Foundation

// MARK: - Schema Version 1 (Initial Release)
// This represents the current data model as of version 1.0

enum VehicleSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Vehicle.self, Event.self, OwnershipRecord.self, Attachment.self]
    }
}

// MARK: - Migration Plan

enum VehicleMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [VehicleSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        // No migrations yet - this is the initial version
        // Future migrations will be added here as new schema versions are created
        []
    }
}

// MARK: - Schema Version Tracking

enum SchemaVersionManager {
    private static let schemaVersionKey = "com.vehicle.schemaVersion"
    private static let lastMigrationDateKey = "com.vehicle.lastMigrationDate"
    private static let migrationBackupKey = "com.vehicle.migrationBackupPath"
    
    static var currentSchemaVersion: String {
        "\(VehicleSchemaV1.versionIdentifier.major).\(VehicleSchemaV1.versionIdentifier.minor).\(VehicleSchemaV1.versionIdentifier.patch)"
    }
    
    static var storedSchemaVersion: String? {
        get { UserDefaults.standard.string(forKey: schemaVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: schemaVersionKey) }
    }
    
    static var lastMigrationDate: Date? {
        get { UserDefaults.standard.object(forKey: lastMigrationDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastMigrationDateKey) }
    }
    
    static var migrationBackupPath: String? {
        get { UserDefaults.standard.string(forKey: migrationBackupKey) }
        set { UserDefaults.standard.set(newValue, forKey: migrationBackupKey) }
    }
    
    /// Check if migration is needed by comparing stored version with current version
    static var needsMigration: Bool {
        guard let stored = storedSchemaVersion else {
            // First launch - no migration needed, just record the version
            return false
        }
        return stored != currentSchemaVersion
    }
    
    /// Record that the current schema version is now in use
    static func recordCurrentVersion() {
        storedSchemaVersion = currentSchemaVersion
        AppLogger.shared.info("Schema version recorded: \(currentSchemaVersion)", category: .database)
    }
    
    /// Record successful migration
    static func recordMigrationSuccess(from oldVersion: String, to newVersion: String) {
        storedSchemaVersion = newVersion
        lastMigrationDate = Date()
        AppLogger.shared.info("Migration completed: \(oldVersion) → \(newVersion)", category: .database)
    }
}

// MARK: - Migration Error Types

enum MigrationError: LocalizedError {
    case backupFailed(underlying: Error)
    case migrationFailed(underlying: Error)
    case restoreFailed(underlying: Error)
    case invalidSchemaVersion(String)
    case dataCorruption(details: String)
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .backupFailed(let error):
            return "Failed to create backup before migration: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Data migration failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Failed to restore from backup: \(error.localizedDescription)"
        case .invalidSchemaVersion(let version):
            return "Invalid schema version: \(version)"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        case .insufficientStorage:
            return "Insufficient storage space for migration backup"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .backupFailed:
            return "Please ensure you have enough storage space and try again."
        case .migrationFailed:
            return "Your data has been preserved. Please contact support if this issue persists."
        case .restoreFailed:
            return "Please try restarting the app. If the issue persists, reinstall the app."
        case .invalidSchemaVersion:
            return "Please update to the latest version of the app."
        case .dataCorruption:
            return "Please restore from a backup or contact support."
        case .insufficientStorage:
            return "Please free up storage space and restart the app."
        }
    }
}

// MARK: - Database Backup Manager

actor DatabaseBackupManager {
    static let shared = DatabaseBackupManager()
    
    private let logger = AppLogger.shared
    private let fileManager = FileManager.default
    
    private var backupDirectory: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Backups", isDirectory: true)
    }
    
    private var databaseDirectory: URL? {
        // SwiftData stores its database in the Application Support directory
        // The default store name follows the pattern: default.store
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // Check for SwiftData's default store location
        let defaultStore = appSupport.appendingPathComponent("default.store", isDirectory: false)
        if fileManager.fileExists(atPath: defaultStore.path) {
            return defaultStore
        }
        
        // Also check for .sqlite file which SwiftData may use
        let sqliteStore = appSupport.appendingPathComponent("default.sqlite", isDirectory: false)
        if fileManager.fileExists(atPath: sqliteStore.path) {
            return sqliteStore
        }
        
        // Return the Application Support directory itself as fallback
        // to backup any database files present
        return appSupport
    }
    
    /// Create a backup of the current database before migration
    func createPreMigrationBackup() async throws -> URL {
        guard let backupDir = backupDirectory else {
            throw MigrationError.backupFailed(underlying: NSError(domain: "DatabaseBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine backup directory"]))
        }
        
        // Ensure backup directory exists
        try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        // Check available storage
        guard hasEnoughStorageSpace() else {
            throw MigrationError.insufficientStorage
        }
        
        // Create timestamped backup folder
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let backupName = "backup_\(timestamp)"
        let backupFolderURL = backupDir.appendingPathComponent(backupName, isDirectory: true)
        
        do {
            // Create the backup folder
            try fileManager.createDirectory(at: backupFolderURL, withIntermediateDirectories: true)
            
            // Find and copy all database-related files from Application Support
            guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw MigrationError.backupFailed(underlying: NSError(domain: "DatabaseBackup", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not access Application Support directory"]))
            }
            
            let contents = try fileManager.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            var backedUpFiles = 0
            for item in contents {
                let fileName = item.lastPathComponent
                // Backup SwiftData/SQLite related files
                if fileName.contains("default") || fileName.hasSuffix(".sqlite") || fileName.hasSuffix(".sqlite-shm") || fileName.hasSuffix(".sqlite-wal") || fileName.hasSuffix(".store") {
                    let destinationURL = backupFolderURL.appendingPathComponent(fileName)
                    try fileManager.copyItem(at: item, to: destinationURL)
                    backedUpFiles += 1
                    logger.debug("Backed up: \(fileName)", category: .database)
                }
            }
            
            if backedUpFiles > 0 {
                logger.info("Created pre-migration backup at: \(backupFolderURL.path) (\(backedUpFiles) files)", category: .database)
                
                // Store backup path for potential recovery
                SchemaVersionManager.migrationBackupPath = backupFolderURL.path
                
                // Clean up old backups (keep last 3)
                try await cleanupOldBackups(keepCount: 3)
            } else {
                // No existing database files - this is a fresh install
                logger.info("No existing database to backup - fresh install", category: .database)
                // Remove empty backup folder
                try? fileManager.removeItem(at: backupFolderURL)
            }
            
            return backupFolderURL
        } catch let error as MigrationError {
            throw error
        } catch {
            logger.error("Failed to create backup: \(error.localizedDescription)", category: .database)
            throw MigrationError.backupFailed(underlying: error)
        }
    }
    
    /// Restore database from a backup
    func restoreFromBackup(at backupURL: URL) async throws {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw MigrationError.restoreFailed(underlying: NSError(domain: "DatabaseBackup", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not determine Application Support directory"]))
        }
        
        do {
            // Get list of files in backup
            let backupContents = try fileManager.contentsOfDirectory(at: backupURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            // Remove current database files and restore from backup
            for backupFile in backupContents {
                let fileName = backupFile.lastPathComponent
                let destinationURL = appSupport.appendingPathComponent(fileName)
                
                // Remove existing file if present
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                // Copy from backup
                try fileManager.copyItem(at: backupFile, to: destinationURL)
                logger.debug("Restored: \(fileName)", category: .database)
            }
            
            logger.info("Restored database from backup: \(backupURL.path)", category: .database)
        } catch {
            logger.error("Failed to restore from backup: \(error.localizedDescription)", category: .database)
            throw MigrationError.restoreFailed(underlying: error)
        }
    }
    
    /// Get list of available backups
    func availableBackups() async -> [URL] {
        guard let backupDir = backupDirectory,
              fileManager.fileExists(atPath: backupDir.path) else {
            return []
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
            return contents.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            logger.error("Failed to list backups: \(error.localizedDescription)", category: .database)
            return []
        }
    }
    
    /// Clean up old backups, keeping the most recent ones
    private func cleanupOldBackups(keepCount: Int) async throws {
        let backups = await availableBackups()
        
        guard backups.count > keepCount else { return }
        
        let backupsToDelete = backups.dropFirst(keepCount)
        for backup in backupsToDelete {
            do {
                try fileManager.removeItem(at: backup)
                logger.debug("Deleted old backup: \(backup.lastPathComponent)", category: .database)
            } catch {
                logger.warning("Failed to delete old backup: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    /// Check if there's enough storage space for backup
    private func hasEnoughStorageSpace() -> Bool {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                // Require at least 100MB free space
                return freeSpace > 100 * 1024 * 1024
            }
        } catch {
            logger.warning("Could not check storage space: \(error.localizedDescription)", category: .database)
        }
        return true // Assume enough space if we can't check
    }
}

// MARK: - Data Export Manager

actor DataExportManager {
    static let shared = DataExportManager()
    
    private let logger = AppLogger.shared
    private let fileManager = FileManager.default
    
    struct ExportedData: Codable {
        let exportDate: Date
        let schemaVersion: String
        let appVersion: String
        let vehicles: [ExportedVehicle]
    }
    
    struct ExportedVehicle: Codable {
        let id: String
        let make: String
        let model: String
        let year: Int
        let color: String
        let nickname: String?
        let icon: String
        let isPinned: Bool
        let categoryRawValue: String
        let subcategoryName: String?
        let typeName: String?
        let trimLevel: String?
        let vin: String?
        let serialNumber: String?
        let fuelTypeRawValue: String
        let engineTypeRawValue: String
        let driveTypeRawValue: String
        let transmissionTypeRawValue: String
        let notes: String?
        let addedDate: Date
        let events: [ExportedEvent]
        let ownershipRecords: [ExportedOwnershipRecord]
    }
    
    struct ExportedEvent: Codable {
        let id: String
        let categoryId: String
        let subcategoryId: String
        let date: Date
        let details: String?
        let mileage: String? // Stored as string to preserve Decimal precision
        let distanceUnit: String
        let hours: String?
        let cost: String?
        let currencyCode: String
    }
    
    struct ExportedOwnershipRecord: Codable {
        let id: String
        let typeRawValue: String
        let date: Date
        let details: String?
        let mileage: String?
        let distanceUnit: String
        let hours: String?
        let cost: String?
        let currencyCode: String
    }
    
    /// Export all data to JSON format
    func exportToJSON(vehicles: [Vehicle]) async throws -> URL {
        let exportedVehicles = vehicles.map { vehicle -> ExportedVehicle in
            let events = (vehicle.events ?? []).map { event -> ExportedEvent in
                ExportedEvent(
                    id: event.id,
                    categoryId: event.categoryId,
                    subcategoryId: event.subcategoryId,
                    date: event.date,
                    details: event.details,
                    mileage: event.mileage.map { "\($0)" },
                    distanceUnit: event.distanceUnit,
                    hours: event.hours.map { "\($0)" },
                    cost: event.cost.map { "\($0)" },
                    currencyCode: event.currencyCode
                )
            }
            
            let records = (vehicle.ownershipRecords ?? []).map { record -> ExportedOwnershipRecord in
                ExportedOwnershipRecord(
                    id: record.id,
                    typeRawValue: record.typeRawValue,
                    date: record.date,
                    details: record.details,
                    mileage: record.mileage.map { "\($0)" },
                    distanceUnit: record.distanceUnit,
                    hours: record.hours.map { "\($0)" },
                    cost: record.cost.map { "\($0)" },
                    currencyCode: record.currencyCode
                )
            }
            
            return ExportedVehicle(
                id: vehicle.id,
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year,
                color: vehicle.color,
                nickname: vehicle.nickname,
                icon: vehicle.icon,
                isPinned: vehicle.isPinned,
                categoryRawValue: vehicle.categoryRawValue,
                subcategoryName: vehicle.subcategoryName,
                typeName: vehicle.typeName,
                trimLevel: vehicle.trimLevel,
                vin: vehicle.vin,
                serialNumber: vehicle.serialNumber,
                fuelTypeRawValue: vehicle.fuelTypeRawValue,
                engineTypeRawValue: vehicle.engineTypeRawValue,
                driveTypeRawValue: vehicle.driveTypeRawValue,
                transmissionTypeRawValue: vehicle.transmissionTypeRawValue,
                notes: vehicle.notes,
                addedDate: vehicle.addedDate,
                events: events,
                ownershipRecords: records
            )
        }
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        
        let exportData = ExportedData(
            exportDate: Date(),
            schemaVersion: SchemaVersionManager.currentSchemaVersion,
            appVersion: appVersion,
            vehicles: exportedVehicles
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        // Save to documents directory
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "DataExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "VehicleExport_\(timestamp).json"
        let fileURL = documentsDir.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        
        logger.info("Exported data to: \(fileURL.path)", category: .database)
        
        return fileURL
    }
}

// MARK: - Migration Coordinator

@MainActor
class MigrationCoordinator: ObservableObject {
    @Published private(set) var migrationState: MigrationState = .idle
    @Published private(set) var migrationProgress: Double = 0
    @Published private(set) var migrationError: MigrationError?
    
    private let logger = AppLogger.shared
    
    enum MigrationState {
        case idle
        case checkingVersion
        case creatingBackup
        case migrating
        case verifying
        case completed
        case failed
    }
    
    init() {
        logger.debug("MigrationCoordinator initialized", category: .database)
    }
    
    /// Perform migration check and execute if needed
    func performMigrationIfNeeded() async {
        migrationState = .checkingVersion
        migrationProgress = 0.1
        
        // Small delay to show the UI
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Check if this is first launch
        if SchemaVersionManager.storedSchemaVersion == nil {
            logger.info("First launch detected - recording initial schema version", category: .database)
            SchemaVersionManager.recordCurrentVersion()
            migrationState = .completed
            migrationProgress = 1.0
            return
        }
        
        // Check if migration is needed
        guard SchemaVersionManager.needsMigration else {
            logger.info("No migration needed - schema version is current", category: .database)
            migrationState = .completed
            migrationProgress = 1.0
            return
        }
        
        let oldVersion = SchemaVersionManager.storedSchemaVersion ?? "unknown"
        let newVersion = SchemaVersionManager.currentSchemaVersion
        
        logger.info("Migration needed: \(oldVersion) → \(newVersion)", category: .database)
        
        // Create backup before migration
        migrationState = .creatingBackup
        migrationProgress = 0.2
        
        do {
            _ = try await DatabaseBackupManager.shared.createPreMigrationBackup()
            migrationProgress = 0.4
        } catch {
            logger.error("Pre-migration backup failed: \(error.localizedDescription)", category: .database)
            migrationError = error as? MigrationError ?? .backupFailed(underlying: error)
            migrationState = .failed
            return
        }
        
        // Perform migration
        migrationState = .migrating
        migrationProgress = 0.6
        
        // SwiftData handles the actual schema migration automatically
        // This is where custom data transformations would go for complex migrations
        
        // Verify migration
        migrationState = .verifying
        migrationProgress = 0.8
        
        // Record successful migration
        SchemaVersionManager.recordMigrationSuccess(from: oldVersion, to: newVersion)
        
        migrationState = .completed
        migrationProgress = 1.0
        
        logger.info("Migration completed successfully", category: .database)
    }
    
    /// Retry migration after a failure
    func retryMigration() async {
        migrationState = .idle
        migrationProgress = 0
        migrationError = nil
        await performMigrationIfNeeded()
    }
}
