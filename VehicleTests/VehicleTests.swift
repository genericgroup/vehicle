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
}
