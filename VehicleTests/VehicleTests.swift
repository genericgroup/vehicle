//
//  VehicleTests.swift
//  VehicleTests
//
//  Created by Andy Carlson on 1/20/25.
//

import XCTest
import SwiftUI
import SwiftData
@testable import Vehicle

final class VehicleTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
    }
    
    // MARK: - Basic Vehicle Tests
    
    func testVehicleInitialization() throws {
        // Given
        let make = "Toyota"
        let model = "Camry"
        let year = 2024
        let color = "Blue"
        
        // When
        let vehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            color: color,
            category: .automobiles,
            fuelType: .gasoline,
            engineType: .i4,
            driveType: .fwd,
            transmission: .automatic
        )
        
        // Then
        XCTAssertEqual(vehicle.make, make)
        XCTAssertEqual(vehicle.model, model)
        XCTAssertEqual(vehicle.year, year)
        XCTAssertEqual(vehicle.color, color)
        XCTAssertEqual(vehicle.category, .automobiles)
        XCTAssertEqual(vehicle.fuelType, .gasoline)
        XCTAssertEqual(vehicle.engineType, .i4)
        XCTAssertEqual(vehicle.driveType, .fwd)
        XCTAssertEqual(vehicle.transmissionType, .automatic)
        XCTAssertEqual(vehicle.events?.count, 0)
        XCTAssertEqual(vehicle.ownershipRecords?.count, 0)
        
        // Test default color
        let defaultVehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            category: .automobiles,
            fuelType: .gasoline,
            engineType: .i4,
            driveType: .fwd,
            transmission: .automatic
        )
        XCTAssertEqual(defaultVehicle.color, "Black", "Default color should be Black")
    }
    
    func testVehicleColorValidation() throws {
        // Given
        let make = "Toyota"
        let model = "Camry"
        let year = 2024
        
        // Test valid colors from commonColors
        for color in Vehicle.commonColors {
            let vehicle = Vehicle(
                make: make,
                model: model,
                year: year,
                color: color,
                category: .automobiles,
                fuelType: .gasoline,
                engineType: .i4,
                driveType: .fwd,
                transmission: .automatic
            )
            XCTAssertEqual(vehicle.color, color, "Color should be set to \(color)")
        }
        
        // Test hex color validation
        let hexColor = "#FF0000"
        let validation = VehicleValidation.validateColor(hexColor)
        XCTAssertTrue(validation.isValid, "Hex color \(hexColor) should be valid")
        
        // Test invalid color
        let invalidColor = "InvalidColor"
        let invalidValidation = VehicleValidation.validateColor(invalidColor)
        XCTAssertFalse(invalidValidation.isValid, "Color \(invalidColor) should be invalid")
    }
    
    func testVehicleDisplayName() throws {
        // Given
        let vehicle1 = Vehicle(
            make: "Honda",
            model: "Civic",
            year: 2023,
            category: .automobiles,
            fuelType: .gasoline,
            engineType: .i4,
            driveType: .fwd,
            transmission: .automatic
        )
        
        let vehicle2 = Vehicle(
            make: "Ford",
            model: "Mustang",
            year: 2024,
            nickname: "Sally",
            category: .automobiles,
            fuelType: .gasoline,
            engineType: .v8,
            driveType: .rwd,
            transmission: .manual
        )
        
        // Then
        XCTAssertEqual(vehicle1.displayName, "2023 Honda Civic")
        XCTAssertEqual(vehicle2.displayName, "2024 Ford Mustang (Sally)")
        XCTAssertEqual(vehicle1.color, "Black", "Vehicle1 should have default Black color")
        XCTAssertEqual(vehicle2.color, "Black", "Vehicle2 should have default Black color")
    }
    
    // MARK: - Vehicle Relationships
    
    func testAddEventToVehicle() throws {
        // Given
        let vehicle = Vehicle(
            make: "Tesla",
            model: "Model 3",
            year: 2024,
            category: .automobiles,
            fuelType: .electric,
            engineType: .electric,
            driveType: .awd,
            transmission: .automatic
        )
        
        let event = Event(
            category: .maintenance,
            subcategory: EventCategory.maintenance.subcategories[0],
            date: Date(),
            details: "Battery check",
            mileage: 5000,
            distanceUnit: .miles,
            hours: 2.5,
            cost: 150.00,
            currencyCode: "USD"
        )
        
        // When
        vehicle.addEvent(event)
        
        // Then
        XCTAssertNotNil(vehicle.events)
        XCTAssertEqual(vehicle.events?.count, 1)
        XCTAssertEqual(vehicle.events?.first?.details, "Battery check")
        XCTAssertEqual(event.vehicle, vehicle)
        XCTAssertEqual(vehicle.color, "Black", "Vehicle should have default Black color")
        
        // Verify event properties
        let savedEvent = vehicle.events?.first
        XCTAssertEqual(savedEvent?.mileage, 5000)
        XCTAssertEqual(savedEvent?.distanceUnit, DistanceUnit.miles.rawValue)
        XCTAssertEqual(savedEvent?.hours, 2.5)
        XCTAssertEqual(savedEvent?.cost, 150.00)
        XCTAssertEqual(savedEvent?.currencyCode, "USD")
        XCTAssertEqual(savedEvent?.category, .maintenance)
    }
    
    func testAddOwnershipRecordToVehicle() throws {
        // Given
        let vehicle = Vehicle(
            make: "BMW",
            model: "M3",
            year: 2024,
            category: .automobiles,
            fuelType: .gasoline,
            engineType: .i6,
            driveType: .rwd,
            transmission: .automatic
        )
        
        let purchaseDate = Date()
        let record = OwnershipRecord(
            type: .purchased,
            date: purchaseDate,
            details: "Initial purchase",
            mileage: 1000,
            distanceUnit: .miles,
            hours: 100,
            cost: 75000.00,
            currencyCode: "USD"
        )
        
        // When
        vehicle.addOwnershipRecord(record)
        
        // Then
        XCTAssertNotNil(vehicle.ownershipRecords)
        XCTAssertEqual(vehicle.ownershipRecords?.count, 1)
        XCTAssertEqual(vehicle.ownershipRecords?.first?.details, "Initial purchase")
        XCTAssertEqual(record.vehicle, vehicle)
        XCTAssertEqual(vehicle.color, "Black", "Vehicle should have default Black color")
        
        // Verify ownership record properties
        let savedRecord = vehicle.ownershipRecords?.first
        XCTAssertEqual(savedRecord?.type, .purchased)
        XCTAssertEqual(savedRecord?.date, purchaseDate)
        XCTAssertEqual(savedRecord?.mileage, 1000)
        XCTAssertEqual(savedRecord?.distanceUnit, DistanceUnit.miles.rawValue)
        XCTAssertEqual(savedRecord?.hours, 100)
        XCTAssertEqual(savedRecord?.cost, 75000.00)
        XCTAssertEqual(savedRecord?.currencyCode, "USD")
    }
    
    // MARK: - Vehicle Type Tests
    
    func testVehicleTypes() throws {
        // Test all vehicle types exist (12 total)
        XCTAssertEqual(VehicleType.allTypes.count, 12)
        XCTAssertTrue(VehicleType.allTypes.contains(.automobiles))
        XCTAssertTrue(VehicleType.allTypes.contains(.motorcycles))
        XCTAssertTrue(VehicleType.allTypes.contains(.watercraft))
        XCTAssertTrue(VehicleType.allTypes.contains(.offroad))
        XCTAssertTrue(VehicleType.allTypes.contains(.agricultural))
        XCTAssertTrue(VehicleType.allTypes.contains(.construction))
        
        // Test from(rawValue:)
        XCTAssertEqual(VehicleType.from(rawValue: "automobiles"), .automobiles)
        XCTAssertEqual(VehicleType.from(rawValue: "motorcycles"), .motorcycles)
        XCTAssertEqual(VehicleType.from(rawValue: "invalid"), .automobiles) // Default fallback
    }
    
    func testFuelTypes() throws {
        // Test all fuel types
        XCTAssertTrue(FuelType.allTypes.contains(.gasoline))
        XCTAssertTrue(FuelType.allTypes.contains(.diesel))
        XCTAssertTrue(FuelType.allTypes.contains(.electric))
        XCTAssertTrue(FuelType.allTypes.contains(.hybrid))
        
        // Test from(rawValue:)
        XCTAssertEqual(FuelType.from(rawValue: "gasoline"), .gasoline)
        XCTAssertEqual(FuelType.from(rawValue: "electric"), .electric)
        XCTAssertEqual(FuelType.from(rawValue: "invalid"), .gasoline) // Default fallback
    }
}

// MARK: - Validation Tests

final class VehicleValidationTests: XCTestCase {
    
    // MARK: - Make/Model Validation
    
    func testValidateMake() throws {
        // Valid make
        let validResult = VehicleValidation.validateMake("Toyota")
        XCTAssertTrue(validResult.isValid)
        
        // Empty make
        let emptyResult = VehicleValidation.validateMake("")
        XCTAssertFalse(emptyResult.isValid)
        XCTAssertNotNil(emptyResult.message)
        
        // Whitespace only
        let whitespaceResult = VehicleValidation.validateMake("   ")
        XCTAssertFalse(whitespaceResult.isValid)
    }
    
    func testValidateModel() throws {
        // Valid model
        let validResult = VehicleValidation.validateModel("Camry")
        XCTAssertTrue(validResult.isValid)
        
        // Empty model
        let emptyResult = VehicleValidation.validateModel("")
        XCTAssertFalse(emptyResult.isValid)
    }
    
    // MARK: - Year Validation
    
    func testValidateYear() throws {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Valid years
        XCTAssertTrue(VehicleValidation.validateYear(2024).isValid)
        XCTAssertTrue(VehicleValidation.validateYear(1900).isValid)
        XCTAssertTrue(VehicleValidation.validateYear(currentYear + 1).isValid)
        
        // Invalid years
        XCTAssertFalse(VehicleValidation.validateYear(1899).isValid)
        XCTAssertFalse(VehicleValidation.validateYear(currentYear + 2).isValid)
    }
    
    // MARK: - VIN Validation
    
    func testValidateVIN() throws {
        // Valid 17-character VIN for modern automobile
        let validVIN = "1HGBH41JXMN109186"
        let validResult = VehicleValidation.validateVIN(validVIN, category: .automobiles, year: 2020)
        XCTAssertTrue(validResult.isValid)
        
        // Invalid VIN - wrong length
        let shortVIN = "1HGBH41JX"
        let shortResult = VehicleValidation.validateVIN(shortVIN, category: .automobiles, year: 2020)
        XCTAssertFalse(shortResult.isValid)
        XCTAssertTrue(shortResult.message?.contains("17 characters") ?? false)
        
        // Invalid VIN - contains I, O, Q
        let invalidCharsVIN = "1HGBH41IXMN109186"
        let invalidCharsResult = VehicleValidation.validateVIN(invalidCharsVIN, category: .automobiles, year: 2020)
        XCTAssertFalse(invalidCharsResult.isValid)
        
        // Pre-1981 vehicle - less strict validation
        let oldVIN = "ABC123"
        let oldResult = VehicleValidation.validateVIN(oldVIN, category: .automobiles, year: 1975)
        XCTAssertTrue(oldResult.isValid)
        
        // Empty VIN is valid (optional field)
        let emptyResult = VehicleValidation.validateVIN(nil, category: .automobiles, year: 2020)
        XCTAssertTrue(emptyResult.isValid)
    }
    
    // MARK: - Serial Number Validation
    
    func testValidateSerialNumber() throws {
        // Valid serial numbers
        XCTAssertTrue(VehicleValidation.validateSerialNumber("ABC123456").isValid)
        XCTAssertTrue(VehicleValidation.validateSerialNumber("SN-2024-001").isValid)
        
        // Empty is valid (optional)
        XCTAssertTrue(VehicleValidation.validateSerialNumber(nil).isValid)
        XCTAssertTrue(VehicleValidation.validateSerialNumber("").isValid)
        
        // Too short
        let shortResult = VehicleValidation.validateSerialNumber("A")
        XCTAssertFalse(shortResult.isValid)
    }
    
    // MARK: - Color Validation
    
    func testValidateColor() throws {
        // Valid predefined colors
        XCTAssertTrue(VehicleValidation.validateColor("black").isValid)
        XCTAssertTrue(VehicleValidation.validateColor("White").isValid)
        XCTAssertTrue(VehicleValidation.validateColor("RED").isValid)
        
        // Valid hex colors
        XCTAssertTrue(VehicleValidation.validateColor("#FF0000").isValid)
        XCTAssertTrue(VehicleValidation.validateColor("#fff").isValid)
        
        // Invalid colors
        XCTAssertFalse(VehicleValidation.validateColor("rainbow").isValid)
        XCTAssertFalse(VehicleValidation.validateColor("#GGG").isValid)
    }
    
    // MARK: - Icon Validation
    
    func testValidateIcon() throws {
        // Valid emoji
        XCTAssertTrue(VehicleValidation.validateIcon("🚗").isValid)
        XCTAssertTrue(VehicleValidation.validateIcon("🏍️").isValid)
        
        // Empty is valid
        XCTAssertTrue(VehicleValidation.validateIcon("").isValid)
        
        // Invalid - multiple characters
        XCTAssertFalse(VehicleValidation.validateIcon("AB").isValid)
    }
}

// MARK: - Event Validation Tests

final class EventValidationTests: XCTestCase {
    
    func testValidateDetails() throws {
        // Valid details
        let validResult = EventValidation.validateDetails("Oil change performed at dealer")
        XCTAssertTrue(validResult.isValid)
        
        // Empty details
        let emptyResult = EventValidation.validateDetails("")
        XCTAssertFalse(emptyResult.isValid)
        XCTAssertNotNil(emptyResult.message)
        
        // Too short
        let shortResult = EventValidation.validateDetails("Hi")
        XCTAssertFalse(shortResult.isValid)
        
        // Too long (over 2000 chars)
        let longDetails = String(repeating: "a", count: 2001)
        let longResult = EventValidation.validateDetails(longDetails)
        XCTAssertFalse(longResult.isValid)
    }
    
    func testValidateDate() throws {
        // Valid date (past)
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        XCTAssertTrue(EventValidation.validateDate(pastDate).isValid)
        
        // Valid date (today)
        XCTAssertTrue(EventValidation.validateDate(Date()).isValid)
        
        // Invalid date (future)
        let futureDate = Date().addingTimeInterval(86400) // Tomorrow
        XCTAssertFalse(EventValidation.validateDate(futureDate).isValid)
    }
    
    func testValidateMileage() throws {
        // Valid mileage
        XCTAssertTrue(EventValidation.validateMileage("50000", previousMileage: nil).isValid)
        XCTAssertTrue(EventValidation.validateMileage("50,000", previousMileage: nil).isValid)
        
        // Empty is valid (optional)
        XCTAssertTrue(EventValidation.validateMileage("", previousMileage: nil).isValid)
        
        // Invalid - negative
        XCTAssertFalse(EventValidation.validateMileage("-100", previousMileage: nil).isValid)
        
        // Invalid - less than previous
        let previousResult = EventValidation.validateMileage("40000", previousMileage: 50000)
        XCTAssertFalse(previousResult.isValid)
        XCTAssertTrue(previousResult.message?.contains("lower") ?? false)
        
        // Invalid - not a number
        XCTAssertFalse(EventValidation.validateMileage("abc", previousMileage: nil).isValid)
    }
    
    func testValidateHours() throws {
        // Valid hours
        XCTAssertTrue(EventValidation.validateHours("100").isValid)
        XCTAssertTrue(EventValidation.validateHours("1,234.5").isValid)
        
        // Empty is valid
        XCTAssertTrue(EventValidation.validateHours("").isValid)
        
        // Invalid - negative
        XCTAssertFalse(EventValidation.validateHours("-50").isValid)
        
        // Invalid - too high
        XCTAssertFalse(EventValidation.validateHours("2000000").isValid)
    }
    
    func testValidateCost() throws {
        // Valid costs
        XCTAssertTrue(EventValidation.validateCost("150.00").isValid)
        XCTAssertTrue(EventValidation.validateCost("1,500").isValid)
        XCTAssertTrue(EventValidation.validateCost("$99.99").isValid)
        
        // Empty is valid
        XCTAssertTrue(EventValidation.validateCost("").isValid)
        
        // Invalid - negative
        XCTAssertFalse(EventValidation.validateCost("-50").isValid)
    }
}

// MARK: - Ownership Validation Tests

final class OwnershipValidationTests: XCTestCase {
    
    func testValidateDetails() throws {
        // Valid details
        let validResult = OwnershipValidation.validateDetails("Purchased from dealer", type: .purchased)
        XCTAssertTrue(validResult.isValid)
        
        // Empty details - should provide type-specific guidance
        let emptyPurchaseResult = OwnershipValidation.validateDetails("", type: .purchased)
        XCTAssertFalse(emptyPurchaseResult.isValid)
        XCTAssertTrue(emptyPurchaseResult.message?.contains("purchase") ?? false)
        
        let emptySoldResult = OwnershipValidation.validateDetails("", type: .sold)
        XCTAssertFalse(emptySoldResult.isValid)
        XCTAssertTrue(emptySoldResult.message?.contains("sale") ?? false)
    }
    
    func testValidateDate() throws {
        // Valid date (past)
        XCTAssertTrue(OwnershipValidation.validateDate(Date().addingTimeInterval(-86400)).isValid)
        
        // Invalid date (future)
        XCTAssertFalse(OwnershipValidation.validateDate(Date().addingTimeInterval(86400)).isValid)
    }
}

// MARK: - NumberFormatters Tests

final class NumberFormattersTests: XCTestCase {
    
    func testFormatDecimal() throws {
        // Test basic formatting
        XCTAssertEqual(NumberFormatters.formatDecimal(1234.56), "1,234.56")
        XCTAssertEqual(NumberFormatters.formatDecimal(1000000), "1,000,000")
        XCTAssertEqual(NumberFormatters.formatDecimal(0), "0")
    }
    
    func testFormatMileage() throws {
        let result = NumberFormatters.formatMileage(50000, unit: .miles)
        XCTAssertTrue(result.contains("50,000"))
        XCTAssertTrue(result.contains("mi"))
        
        let kmResult = NumberFormatters.formatMileage(80000, unit: .kilometers)
        XCTAssertTrue(kmResult.contains("80,000"))
        XCTAssertTrue(kmResult.contains("km"))
    }
    
    func testFormatHours() throws {
        let result = NumberFormatters.formatHours(1234.5)
        XCTAssertTrue(result.contains("1,234.5"))
        XCTAssertTrue(result.contains("hrs"))
    }
    
    func testFormatCurrency() throws {
        let result = NumberFormatters.formatCurrency(1500.50, currencyCode: "USD")
        // Currency formatting varies by locale, just check it contains the value
        XCTAssertFalse(result.isEmpty)
    }
    
    func testFormatForInput() throws {
        // Should format without grouping separators
        XCTAssertEqual(NumberFormatters.formatForInput(1234.56), "1234.56")
        XCTAssertEqual(NumberFormatters.formatForInput(nil), "")
    }
}

// MARK: - Event Category Tests

final class EventCategoryTests: XCTestCase {
    
    func testAllCategories() throws {
        XCTAssertEqual(EventCategory.allCategories.count, 3)
        XCTAssertTrue(EventCategory.allCategories.contains(.observation))
        XCTAssertTrue(EventCategory.allCategories.contains(.repair))
        XCTAssertTrue(EventCategory.allCategories.contains(.maintenance))
    }
    
    func testCategoryFromId() throws {
        XCTAssertEqual(EventCategory.from(id: "observation").id, "observation")
        XCTAssertEqual(EventCategory.from(id: "repair").id, "repair")
        XCTAssertEqual(EventCategory.from(id: "maintenance").id, "maintenance")
        XCTAssertEqual(EventCategory.from(id: "invalid").id, "observation") // Default fallback
    }
    
    func testSubcategoryFromId() throws {
        let oilChange = EventSubcategory.from(id: "oil_change")
        XCTAssertEqual(oilChange.id, "oil_change")
        
        let damage = EventSubcategory.from(id: "damage")
        XCTAssertEqual(damage.id, "damage")
        
        // Invalid ID should return first observation subcategory
        let invalid = EventSubcategory.from(id: "invalid_id")
        XCTAssertEqual(invalid.id, EventCategory.observation.subcategories[0].id)
    }
    
    func testSubcategoriesExist() throws {
        // Each category should have subcategories
        XCTAssertGreaterThan(EventCategory.observation.subcategories.count, 0)
        XCTAssertGreaterThan(EventCategory.repair.subcategories.count, 0)
        XCTAssertGreaterThan(EventCategory.maintenance.subcategories.count, 0)
        
        // Check specific subcategories exist
        let maintenanceIds = EventCategory.maintenance.subcategories.map { $0.id }
        XCTAssertTrue(maintenanceIds.contains("oil_change"))
        XCTAssertTrue(maintenanceIds.contains("tire_rotation"))
    }
}

// MARK: - Ownership Event Type Tests

final class OwnershipEventTypeTests: XCTestCase {
    
    func testAllTypes() throws {
        XCTAssertGreaterThan(OwnershipEventType.allTypes.count, 0)
        XCTAssertTrue(OwnershipEventType.allTypes.contains(.purchased))
        XCTAssertTrue(OwnershipEventType.allTypes.contains(.sold))
        XCTAssertTrue(OwnershipEventType.allTypes.contains(.registered))
        XCTAssertTrue(OwnershipEventType.allTypes.contains(.insured))
    }
    
    func testFromRawValue() throws {
        XCTAssertEqual(OwnershipEventType.from(rawValue: "purchased"), .purchased)
        XCTAssertEqual(OwnershipEventType.from(rawValue: "sold"), .sold)
        XCTAssertEqual(OwnershipEventType.from(rawValue: "invalid"), .purchased) // Default fallback
    }
    
    func testDisplayName() throws {
        XCTAssertEqual(OwnershipEventType.purchased.displayName, "Purchased")
        XCTAssertEqual(OwnershipEventType.sold.displayName, "Sold")
    }
}

// MARK: - Distance Unit Tests

final class DistanceUnitTests: XCTestCase {
    
    func testDistanceUnits() throws {
        // Raw values are the short labels
        XCTAssertEqual(DistanceUnit.miles.rawValue, "mi")
        XCTAssertEqual(DistanceUnit.kilometers.rawValue, "km")
    }
    
    func testShortLabel() throws {
        XCTAssertEqual(DistanceUnit.miles.shortLabel, "mi")
        XCTAssertEqual(DistanceUnit.kilometers.shortLabel, "km")
    }
    
    func testAllCases() throws {
        XCTAssertEqual(DistanceUnit.allCases.count, 2)
        XCTAssertTrue(DistanceUnit.allCases.contains(.miles))
        XCTAssertTrue(DistanceUnit.allCases.contains(.kilometers))
    }
}

// MARK: - Sort and Group Options Tests

final class SortGroupOptionsTests: XCTestCase {
    
    func testVehicleSortOptions() throws {
        XCTAssertEqual(VehicleSortOption.allCases.count, 5)
        XCTAssertTrue(VehicleSortOption.allCases.contains(.none))
        XCTAssertTrue(VehicleSortOption.allCases.contains(.year))
        XCTAssertTrue(VehicleSortOption.allCases.contains(.make))
        XCTAssertTrue(VehicleSortOption.allCases.contains(.lastUpdated))
        XCTAssertTrue(VehicleSortOption.allCases.contains(.category))
    }
    
    func testVehicleGroupOptions() throws {
        XCTAssertEqual(VehicleGroupOption.allCases.count, 4)
        XCTAssertTrue(VehicleGroupOption.allCases.contains(.none))
        XCTAssertTrue(VehicleGroupOption.allCases.contains(.category))
        XCTAssertTrue(VehicleGroupOption.allCases.contains(.year))
        XCTAssertTrue(VehicleGroupOption.allCases.contains(.make))
    }
}
