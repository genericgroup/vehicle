import SwiftUI
import SwiftData

/// Provides undo support for destructive operations
@MainActor
class UndoCoordinator: ObservableObject {
    static let shared = UndoCoordinator()
    
    /// The last deleted vehicle data for potential undo
    @Published private(set) var canUndoVehicleDelete = false
    @Published private(set) var undoMessage: String?
    
    private var deletedVehicleData: VehicleSnapshot?
    private var undoTimer: Timer?
    private let undoTimeout: TimeInterval = 10.0 // 10 seconds to undo
    
    private let logger = AppLogger.shared
    
    private init() {}
    
    /// Store vehicle data before deletion for potential undo
    func prepareVehicleForDeletion(_ vehicle: Vehicle) -> VehicleSnapshot {
        let snapshot = VehicleSnapshot(from: vehicle)
        deletedVehicleData = snapshot
        canUndoVehicleDelete = true
        undoMessage = "Vehicle '\(vehicle.displayName)' deleted"
        
        // Start undo timeout
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: undoTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.clearUndoState()
            }
        }
        
        logger.debug("Prepared vehicle for deletion with undo support: \(vehicle.id)", category: .database)
        return snapshot
    }
    
    /// Restore the last deleted vehicle
    func undoVehicleDeletion(in context: ModelContext) -> Vehicle? {
        guard let snapshot = deletedVehicleData else {
            logger.warning("No vehicle data available to undo", category: .database)
            return nil
        }
        
        let vehicle = snapshot.restore(in: context)
        clearUndoState()
        
        logger.info("Restored vehicle from undo: \(vehicle.id)", category: .database)
        HapticManager.standardSuccess()
        
        return vehicle
    }
    
    /// Clear the undo state
    func clearUndoState() {
        undoTimer?.invalidate()
        undoTimer = nil
        deletedVehicleData = nil
        canUndoVehicleDelete = false
        undoMessage = nil
    }
}

/// A snapshot of vehicle data that can be restored
struct VehicleSnapshot {
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
    
    // Snapshots of related data
    let events: [EventSnapshot]
    let ownershipRecords: [OwnershipRecordSnapshot]
    
    init(from vehicle: Vehicle) {
        self.id = vehicle.id
        self.make = vehicle.make
        self.model = vehicle.model
        self.year = vehicle.year
        self.color = vehicle.color
        self.nickname = vehicle.nickname
        self.icon = vehicle.icon
        self.isPinned = vehicle.isPinned
        self.categoryRawValue = vehicle.categoryRawValue
        self.subcategoryName = vehicle.subcategoryName
        self.typeName = vehicle.typeName
        self.trimLevel = vehicle.trimLevel
        self.vin = vehicle.vin
        self.serialNumber = vehicle.serialNumber
        self.fuelTypeRawValue = vehicle.fuelTypeRawValue
        self.engineTypeRawValue = vehicle.engineTypeRawValue
        self.driveTypeRawValue = vehicle.driveTypeRawValue
        self.transmissionTypeRawValue = vehicle.transmissionTypeRawValue
        self.notes = vehicle.notes
        self.addedDate = vehicle.addedDate
        self.events = (vehicle.events ?? []).map { EventSnapshot(from: $0) }
        self.ownershipRecords = (vehicle.ownershipRecords ?? []).map { OwnershipRecordSnapshot(from: $0) }
    }
    
    func restore(in context: ModelContext) -> Vehicle {
        let vehicle = Vehicle(
            id: UUID().uuidString, // New ID to avoid conflicts
            make: make,
            model: model,
            year: year,
            color: color,
            nickname: nickname,
            icon: icon,
            isPinned: isPinned,
            category: VehicleType.from(rawValue: categoryRawValue),
            subcategory: nil,
            vehicleType: nil,
            trimLevel: trimLevel,
            vin: vin,
            serialNumber: serialNumber,
            fuelType: FuelType.from(rawValue: fuelTypeRawValue),
            engineType: EngineType.from(rawValue: engineTypeRawValue),
            driveType: DriveType.from(rawValue: driveTypeRawValue),
            transmission: TransmissionType.from(rawValue: transmissionTypeRawValue),
            notes: notes
        )
        
        // Restore subcategory and type
        vehicle.subcategoryName = subcategoryName
        vehicle.typeName = typeName
        
        context.insert(vehicle)
        
        // Restore events using the proper method
        for eventSnapshot in events {
            let event = eventSnapshot.restore(for: vehicle)
            context.insert(event)
            vehicle.addEvent(event)
        }
        
        // Restore ownership records using the proper method
        for recordSnapshot in ownershipRecords {
            let record = recordSnapshot.restore(for: vehicle)
            context.insert(record)
            vehicle.addOwnershipRecord(record)
        }
        
        return vehicle
    }
}

struct EventSnapshot {
    let categoryId: String
    let subcategoryId: String
    let date: Date
    let details: String?
    let mileage: Decimal?
    let distanceUnit: String
    let hours: Decimal?
    let cost: Decimal?
    let currencyCode: String
    
    init(from event: Event) {
        self.categoryId = event.categoryId
        self.subcategoryId = event.subcategoryId
        self.date = event.date
        self.details = event.details
        self.mileage = event.mileage
        self.distanceUnit = event.distanceUnit
        self.hours = event.hours
        self.cost = event.cost
        self.currencyCode = event.currencyCode
    }
    
    func restore(for vehicle: Vehicle) -> Event {
        let event = Event(
            category: EventCategory.from(id: categoryId),
            subcategory: EventSubcategory.from(id: subcategoryId),
            date: date,
            details: details,
            mileage: mileage,
            distanceUnit: DistanceUnit(rawValue: distanceUnit) ?? .miles,
            hours: hours,
            cost: cost,
            currencyCode: currencyCode
        )
        event.vehicle = vehicle
        return event
    }
}

struct OwnershipRecordSnapshot {
    let typeRawValue: String
    let date: Date
    let details: String?
    let mileage: Decimal?
    let distanceUnit: String
    let hours: Decimal?
    let cost: Decimal?
    let currencyCode: String
    
    init(from record: OwnershipRecord) {
        self.typeRawValue = record.typeRawValue
        self.date = record.date
        self.details = record.details
        self.mileage = record.mileage
        self.distanceUnit = record.distanceUnit
        self.hours = record.hours
        self.cost = record.cost
        self.currencyCode = record.currencyCode
    }
    
    func restore(for vehicle: Vehicle) -> OwnershipRecord {
        let record = OwnershipRecord(
            type: OwnershipEventType.from(rawValue: typeRawValue),
            date: date,
            details: details,
            mileage: mileage,
            distanceUnit: DistanceUnit(rawValue: distanceUnit) ?? .miles,
            hours: hours,
            cost: cost,
            currencyCode: currencyCode
        )
        record.vehicle = vehicle
        return record
    }
}
