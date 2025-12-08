//
//  VehicleUITests.swift
//  VehicleUITests
//
//  Created by Andy Carlson on 1/20/25.
//

import XCTest

final class VehicleUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UITESTING": "1"]
        app.launch()
        
        // Wait for app to be ready - look for key UI elements
        // Use Add Menu button as the indicator since it's always visible
        let addButton = app.buttons["Add Menu"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 30), "App failed to launch - Add Menu button not found")
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunches() throws {
        // Verify Add Menu button exists (already checked in setup)
        XCTAssertTrue(app.buttons["Add Menu"].exists)
    }
    
    func testMainUIElementsExist() throws {
        // Verify Add Menu button
        let addButton = app.buttons["Add Menu"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Menu button should exist")
        
        // Verify Settings button
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
    }
    
    func testEmptyStateDisplayed() throws {
        // On iPad with NavigationSplitView, we might see "Select a Vehicle" instead of "No Vehicles"
        // Check for either empty state message
        let noVehicles = app.staticTexts["No Vehicles"]
        let selectVehicle = app.staticTexts["Select a Vehicle"]
        
        // Wait and check if either exists
        let foundEmptyState = noVehicles.waitForExistence(timeout: 5) || selectVehicle.exists
        XCTAssertTrue(foundEmptyState, "Empty state should be visible (No Vehicles or Select a Vehicle)")
    }
    
    // MARK: - Navigation Tests
    
    func testAddMenuOpens() throws {
        let addButton = app.buttons["Add Menu"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        // Verify menu items appear
        let addVehicleOption = app.buttons["Add Vehicle"]
        XCTAssertTrue(addVehicleOption.waitForExistence(timeout: 3), "Add Vehicle option should appear in menu")
    }
    
    func testSettingsOpens() throws {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // Verify Settings sheet appears - look for Done button which is always in Settings
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Settings sheet should open (Done button visible)")
        
        // Dismiss settings
        doneButton.tap()
        
        // Verify we're back to main view (Add Menu button visible again)
        XCTAssertTrue(app.buttons["Add Menu"].waitForExistence(timeout: 5))
    }
    
    func testAddVehicleSheetOpens() throws {
        // Open Add Menu
        let addButton = app.buttons["Add Menu"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        // Tap Add Vehicle
        let addVehicleOption = app.buttons["Add Vehicle"]
        XCTAssertTrue(addVehicleOption.waitForExistence(timeout: 3))
        addVehicleOption.tap()
        
        // Verify Add Vehicle sheet appears - look for Cancel button which is always present
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Add Vehicle sheet should open (Cancel button visible)")
        
        // Cancel and return to main view
        cancelButton.tap()
        
        // Verify we're back to main view (Add Menu button visible again)
        XCTAssertTrue(app.buttons["Add Menu"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
