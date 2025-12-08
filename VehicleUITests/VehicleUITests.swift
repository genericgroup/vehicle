//
//  VehicleUITests.swift
//  VehicleUITests
//
//  Created by Andy Carlson on 1/20/25.
//

import XCTest

final class VehicleUITests: XCTestCase {
    var app: XCUIApplication!
    
    // MARK: - Helper Methods
    
    /// Optimized element wait - uses simple waitForExistence instead of heavy predicate expectations
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    private func waitForNavigationBar() -> Bool {
        return app.navigationBars["Vehicles"].waitForExistence(timeout: 10)
    }
    
    private func waitForAndTapButton(_ identifier: String) -> Bool {
        let button = app.buttons[identifier]
        guard button.waitForExistence(timeout: 5) else { return false }
        button.tap()
        return true
    }
    
    private func waitForAndTypeText(_ text: String, into field: XCUIElement) -> Bool {
        guard field.waitForExistence(timeout: 5) else { return false }
        field.tap()
        field.clearText()
        field.typeText(text)  // Type all at once - much faster
        return true
    }
    
    private func waitForAndSelectPickerValue(_ value: String) -> Bool {
        let pickerWheel = app.pickerWheels.firstMatch
        guard waitForElement(pickerWheel) else { return false }
        pickerWheel.adjust(toPickerWheelValue: value)
        return true
    }
    
    private func clearSearchField() -> Bool {
        let clearButton = app.buttons["Clear text"]
        guard waitForElement(clearButton) else { return false }
        clearButton.tap()
        return true
    }
    
    private func dismissSheet() -> Bool {
        return waitForAndTapButton("Done")
    }
    
    /// Simplified retry - just use longer timeout instead of multiple retries with screenshots
    private func waitForElementWithRetry(_ element: XCUIElement, timeout: TimeInterval = 5, retries: Int = 2) -> Bool {
        // Use total timeout instead of multiple retries - much faster
        return element.waitForExistence(timeout: timeout * Double(retries))
    }
    
    private func verifyEmptyState() -> Bool {
        guard waitForNavigationBar() else { return false }
        return app.staticTexts["No Vehicles"].waitForExistence(timeout: 5)
    }
    
    private func addBasicVehicle(make: String, model: String) -> Bool {
        // Navigate to add form
        guard waitForAndTapButton("Add Menu"),
              waitForAndTapButton("Add Vehicle") else { return false }
        
        // Wait for form to fully appear (sheet animation)
        let makeField = app.textFields["Make*"]
        guard makeField.waitForExistence(timeout: 5) else { return false }
        
        // Small delay for layout to stabilize after sheet animation
        Thread.sleep(forTimeInterval: 0.3)
        
        // Fill required fields
        let modelField = app.textFields["Model*"]
        
        guard waitForAndTypeText(make, into: makeField),
              waitForAndTypeText(model, into: modelField) else { return false }
        
        // Set category
        guard waitForAndTapButton("Category*"),
              waitForAndTapButton("Automobiles"),
              waitForAndTapButton("Car") else { return false }
        
        // Save and verify return to main screen
        guard waitForAndTapButton("Save") else { return false }
        return waitForNavigationBar()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing - minimal flags for speed
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UITESTING": "1"]
        
        app.launch()
        
        // Wait for app to be ready - reduced timeout
        let navBar = app.navigationBars["Vehicles"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 15), "App failed to load")
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Navigation Tests
    
    func testInitialViewExists() throws {
        // Verify the main navigation title exists
        XCTAssertTrue(waitForNavigationBar())
        
        // Verify the add button exists (plus symbol)
        XCTAssertTrue(waitForElement(app.buttons["Add Menu"]))
        
        // Verify settings button exists (gear symbol)
        XCTAssertTrue(waitForElement(app.buttons["Settings"]))
    }
    
    func testEmptyStateMessage() throws {
        XCTAssertTrue(waitForNavigationBar())
        XCTAssertTrue(app.staticTexts["No Vehicles"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Add your first vehicle to get started"].waitForExistence(timeout: 5))
    }
    
    func testAddVehicleSheetPresentation() throws {
        XCTAssertTrue(waitForAndTapButton("Add Menu"))
        XCTAssertTrue(waitForAndTapButton("Add Vehicle"))
        
        // Verify form sections
        XCTAssertTrue(app.staticTexts["BASIC INFORMATION"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["CATEGORIZATION"].waitForExistence(timeout: 3))
        
        // Verify required fields
        let makeField = app.textFields["Make*"]
        XCTAssertTrue(makeField.waitForExistence(timeout: 3))
        
        let modelField = app.textFields["Model*"]
        XCTAssertTrue(modelField.waitForExistence(timeout: 3))
        
        // Cancel and verify return to main view
        XCTAssertTrue(waitForAndTapButton("Cancel"))
        XCTAssertTrue(waitForNavigationBar())
    }
    
    // MARK: - Vehicle Addition Tests
    
    func testAddBasicVehicle() throws {
        XCTAssertTrue(addBasicVehicle(make: "Toyota", model: "Camry"))
        
        // Check if vehicle appears - use predicate for partial match
        let vehiclePredicate = NSPredicate(format: "label CONTAINS 'Toyota' AND label CONTAINS 'Camry'")
        let vehicleCell = app.staticTexts.matching(vehiclePredicate).firstMatch
        XCTAssertTrue(vehicleCell.waitForExistence(timeout: 10), "Vehicle should appear in the list")
    }
    
    func testAddVehicleWithAllFields() throws {
        // Navigate to add vehicle form
        XCTAssertTrue(waitForAndTapButton("Add Menu"))
        XCTAssertTrue(waitForAndTapButton("Add Vehicle"))
        
        // Fill in required fields
        XCTAssertTrue(waitForAndTypeText("Ford", into: app.textFields["Make*"]))
        XCTAssertTrue(waitForAndTypeText("Mustang", into: app.textFields["Model*"]))
        
        // Add nickname
        XCTAssertTrue(waitForAndTypeText("Sally", into: app.textFields["Nickname"]))
        
        // Set category
        XCTAssertTrue(waitForAndTapButton("Category*"))
        XCTAssertTrue(waitForAndTapButton("Automobiles"))
        XCTAssertTrue(waitForAndTapButton("Car"))
        
        // Save
        XCTAssertTrue(waitForAndTapButton("Save"))
        XCTAssertTrue(waitForNavigationBar())
        
        // Verify vehicle appears using predicate
        let vehiclePredicate = NSPredicate(format: "label CONTAINS 'Ford' AND label CONTAINS 'Mustang'")
        let vehicleCell = app.staticTexts.matching(vehiclePredicate).firstMatch
        XCTAssertTrue(vehicleCell.waitForExistence(timeout: 10), "Vehicle should appear in the list")
    }
    
    // MARK: - Sort and Filter Tests
    
    func testSortMenuExists() throws {
        XCTAssertTrue(waitForAndTapButton("Settings"))
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["APPEARANCE"].waitForExistence(timeout: 5))
        
        // Verify sort picker exists
        let sortPicker = app.cells["Sort Vehicles By"]
        XCTAssertTrue(sortPicker.waitForExistence(timeout: 5))
        
        // Dismiss settings
        XCTAssertTrue(waitForAndTapButton("Done"))
        XCTAssertTrue(waitForNavigationBar())
    }
    
    func testGroupMenuExists() throws {
        XCTAssertTrue(waitForAndTapButton("Settings"))
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        
        // Verify group picker exists
        let groupPicker = app.cells["Group Vehicles By"]
        XCTAssertTrue(groupPicker.waitForExistence(timeout: 5))
        
        // Dismiss settings
        XCTAssertTrue(waitForAndTapButton("Done"))
        XCTAssertTrue(waitForNavigationBar())
    }
    
    // MARK: - Search Tests
    
    func testSearchFieldExists() throws {
        let searchField = app.searchFields["Search vehicles, events, and records"]
        XCTAssertTrue(waitForElement(searchField))
        XCTAssertTrue(waitForAndTypeText("Toyota", into: searchField))
        XCTAssertTrue(clearSearchField())
    }
    
    func testSearchFunctionality() throws {
        // Add a test vehicle first
        XCTAssertTrue(addBasicVehicle(make: "Toyota", model: "Camry"))
        
        // Search for the vehicle
        let searchField = app.searchFields["Search vehicles, events, and records"]
        XCTAssertTrue(waitForAndTypeText("Toyota", into: searchField))
        
        // Verify vehicle appears using predicate
        let vehiclePredicate = NSPredicate(format: "label CONTAINS 'Toyota'")
        let vehicleCell = app.staticTexts.matching(vehiclePredicate).firstMatch
        XCTAssertTrue(vehicleCell.waitForExistence(timeout: 10), "Vehicle should appear in search results")
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// Add extension for text field clearing
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        
        // Move cursor to the end of text
        tap()
        
        // Delete characters
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
