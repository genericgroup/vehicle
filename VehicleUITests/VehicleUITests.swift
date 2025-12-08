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
    
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        
        if result != .completed {
            // Take a screenshot and log the UI hierarchy
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.lifetime = .keepAlways
            add(attachment)
            
            let hierarchy = app.debugDescription
            let hierarchyAttachment = XCTAttachment(string: hierarchy)
            hierarchyAttachment.lifetime = .keepAlways
            hierarchyAttachment.name = "UI Hierarchy - Element Not Found"
            add(hierarchyAttachment)
            
            return false
        }
        return true
    }
    
    private func waitForNavigationBar() -> Bool {
        // Wait longer for initial navigation bar due to initialization
        let navBar = app.navigationBars["Vehicles"]
        let exists = waitForElement(navBar, timeout: 30)
        
        if !exists {
            // Log additional information about the navigation bar
            let hierarchy = app.navigationBars.debugDescription
            let attachment = XCTAttachment(string: hierarchy)
            attachment.lifetime = .keepAlways
            attachment.name = "Navigation Bars Hierarchy"
            add(attachment)
        }
        
        return exists
    }
    
    private func waitForAndTapButton(_ identifier: String) -> Bool {
        let button = app.buttons[identifier]
        guard waitForElement(button) else { return false }
        
        // Add a small delay before tapping to ensure UI is stable
        Thread.sleep(forTimeInterval: 0.5)
        button.tap()
        
        // Add a small delay after tapping to allow for animations
        Thread.sleep(forTimeInterval: 0.5)
        return true
    }
    
    private func waitForAndTypeText(_ text: String, into field: XCUIElement) -> Bool {
        guard waitForElement(field) else { return false }
        
        // Clear existing text if any
        field.tap()
        field.clearText()
        
        // Type the text with a small delay between characters
        for char in text {
            field.typeText(String(char))
            Thread.sleep(forTimeInterval: 0.1)
        }
        
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
    
    private func waitForElementWithRetry(_ element: XCUIElement, timeout: TimeInterval = 10, retries: Int = 3) -> Bool {
        for attempt in 1...retries {
            if waitForElement(element, timeout: timeout) {
                return true
            }
            
            // Log retry attempt
            print("Retry attempt \(attempt) for element: \(element.description)")
            
            if attempt < retries {
                // Take a screenshot for debugging
                let screenshot = XCUIScreen.main.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.lifetime = .keepAlways
                attachment.name = "Retry \(attempt)"
                add(attachment)
                
                // Longer delay between retries
                Thread.sleep(forTimeInterval: 2.0)
            }
        }
        return false
    }
    
    private func verifyEmptyState() -> Bool {
        // First verify we're on the main screen
        guard waitForNavigationBar() else { return false }
        
        // Check for empty state with retries
        let emptyStateView = app.staticTexts["No Vehicles"]
        guard waitForElementWithRetry(emptyStateView) else { return false }
        
        let emptyDescription = app.staticTexts["Add your first vehicle to get started"]
        return waitForElementWithRetry(emptyDescription)
    }
    
    private func addBasicVehicle(make: String, model: String) -> Bool {
        // Navigate to add form with retries
        guard waitForElementWithRetry(app.buttons["Add Menu"]),
              waitForAndTapButton("Add Menu"),
              waitForElementWithRetry(app.buttons["Add Vehicle"]),
              waitForAndTapButton("Add Vehicle") else { return false }
        
        // Fill required fields
        let makeField = app.textFields["Make*"]
        let modelField = app.textFields["Model*"]
        
        guard waitForAndTypeText(make, into: makeField),
              waitForAndTypeText(model, into: modelField) else { return false }
        
        // Set category with retries
        guard waitForElementWithRetry(app.buttons["Category*"]),
              waitForAndTapButton("Category*"),
              waitForElementWithRetry(app.buttons["Automobiles"]),
              waitForAndTapButton("Automobiles"),
              waitForElementWithRetry(app.buttons["Car"]),
              waitForAndTapButton("Car") else { return false }
        
        // Save and verify return to main screen
        guard waitForAndTapButton("Save") else { return false }
        return waitForNavigationBar()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing with more explicit flags
        app.launchArguments = [
            "UI-Testing",
            "RESET-DATABASE",  // Reset database for each test
            "DISABLE-CLOUDKIT",  // Disable CloudKit for testing
            "DISABLE-ANIMATIONS"  // Disable animations for more reliable tests
        ]
        
        app.launchEnvironment = [
            "UITESTING": "1",
            "RESET_DATABASE": "1",
            "DISABLE_CLOUDKIT": "1",
            "DISABLE_ANIMATIONS": "1",
            "TESTING_TIMEOUT": "30"  // Longer timeout for testing
        ]
        
        // Launch and wait for initialization
        app.launch()
        
        // Wait for the app to be fully initialized
        let navBar = app.navigationBars["Vehicles"]
        let exists = navBar.waitForExistence(timeout: 30)  // Increased timeout
        
        if !exists {
            // Take a screenshot and log the UI hierarchy
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.lifetime = .keepAlways
            add(attachment)
            
            // Add UI hierarchy for debugging
            let hierarchy = app.debugDescription
            let hierarchyAttachment = XCTAttachment(string: hierarchy)
            hierarchyAttachment.lifetime = .keepAlways
            hierarchyAttachment.name = "UI Hierarchy"
            add(hierarchyAttachment)
            
            XCTFail("App failed to load initial view - Initialization may be incomplete")
        }
        
        // Additional wait to ensure database is ready
        Thread.sleep(forTimeInterval: 2.0)
    }

    override func tearDownWithError() throws {
        // Take a final screenshot if the test failed
        if testRun?.hasBeenSkipped ?? false || testRun?.failureCount ?? 0 > 0 {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.lifetime = .keepAlways
            attachment.name = "Final State"
            add(attachment)
        }
        
        app.terminate()
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
        // First ensure we're on the main screen and database is initialized
        XCTAssertTrue(waitForNavigationBar())
        
        // Wait for the database to be ready by checking for the empty state message
        let emptyStateTitle = app.staticTexts["No Vehicles"]
        XCTAssertTrue(waitForElementWithRetry(emptyStateTitle, timeout: 5, retries: 6))
        
        let emptyStateDescription = app.staticTexts["Add your first vehicle to get started"]
        XCTAssertTrue(waitForElementWithRetry(emptyStateDescription, timeout: 5, retries: 6))
    }
    
    func testAddVehicleSheetPresentation() throws {
        // Navigate to add vehicle form with retries
        XCTAssertTrue(waitForAndTapButton("Add Menu"))
        XCTAssertTrue(waitForAndTapButton("Add Vehicle"))
        
        // Verify form sections with retries
        let basicInfoHeader = app.staticTexts["BASIC INFORMATION"]
        XCTAssertTrue(waitForElementWithRetry(basicInfoHeader, timeout: 5, retries: 3))
        
        let categorizationHeader = app.staticTexts["CATEGORIZATION"]
        XCTAssertTrue(waitForElementWithRetry(categorizationHeader, timeout: 5, retries: 3))
        
        // Verify required fields with retries
        let makeField = app.textFields["Make*"]
        XCTAssertTrue(waitForElementWithRetry(makeField, timeout: 5, retries: 3))
        XCTAssertEqual(makeField.placeholderValue, "Required")
        
        let modelField = app.textFields["Model*"]
        XCTAssertTrue(waitForElementWithRetry(modelField, timeout: 5, retries: 3))
        XCTAssertEqual(modelField.placeholderValue, "Required")
        
        // Verify category picker with retries
        let categoryPicker = app.buttons["Category*"]
        XCTAssertTrue(waitForElementWithRetry(categoryPicker, timeout: 5, retries: 3))
        
        // Cancel and verify return to main view
        XCTAssertTrue(waitForAndTapButton("Cancel"))
        XCTAssertTrue(waitForNavigationBar())
    }
    
    // MARK: - Vehicle Addition Tests
    
    func testAddBasicVehicle() throws {
        XCTAssertTrue(addBasicVehicle(make: "Toyota", model: "Camry"))
        
        // Wait for the vehicle to appear in the list
        // The vehicle name could be displayed in different formats depending on the group option
        // Try all possible formats
        let currentYear = Calendar.current.component(.year, from: Date())
        let possibleNames = [
            "\(currentYear) Toyota Camry",  // No grouping
            "Toyota Camry",                 // Year grouping
            "\(currentYear) Camry",         // Make grouping
            "\(currentYear) Toyota Camry"   // Category grouping
        ]
        
        var vehicleFound = false
        for name in possibleNames {
            let vehicleCell = app.staticTexts[name]
            if waitForElementWithRetry(vehicleCell, timeout: 5, retries: 3) {
                vehicleFound = true
                break
            }
        }
        
        XCTAssertTrue(vehicleFound, "Vehicle should appear in the list with one of the expected formats")
    }
    
    func testAddVehicleWithAllFields() throws {
        // Navigate to add vehicle form with retries
        XCTAssertTrue(waitForElementWithRetry(app.buttons["Add Menu"], timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTapButton("Add Menu"))
        XCTAssertTrue(waitForElementWithRetry(app.buttons["Add Vehicle"], timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTapButton("Add Vehicle"))
        
        // Fill in all fields with retries
        let makeField = app.textFields["Make*"]
        XCTAssertTrue(waitForElementWithRetry(makeField, timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTypeText("Ford", into: makeField))
        
        let modelField = app.textFields["Model*"]
        XCTAssertTrue(waitForElementWithRetry(modelField, timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTypeText("Mustang", into: modelField))
        
        // Set year with retries
        let yearButton = app.buttons["Year"]
        XCTAssertTrue(waitForElementWithRetry(yearButton, timeout: 5, retries: 3))
        yearButton.tap()
        XCTAssertTrue(waitForElementWithRetry(app.pickerWheels.firstMatch, timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndSelectPickerValue("2023"))
        
        // Set color with retries
        let colorButton = app.buttons["Color"]
        XCTAssertTrue(waitForElementWithRetry(colorButton, timeout: 5, retries: 3))
        colorButton.tap()
        let redButton = app.buttons["Red"]
        XCTAssertTrue(waitForElementWithRetry(redButton, timeout: 5, retries: 3))
        redButton.tap()
        
        // Add nickname with retries
        let nicknameField = app.textFields["Nickname"]
        XCTAssertTrue(waitForElementWithRetry(nicknameField, timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTypeText("Sally", into: nicknameField))
        
        // Set category with retries
        let categoryButton = app.buttons["Category*"]
        XCTAssertTrue(waitForElementWithRetry(categoryButton, timeout: 5, retries: 3))
        categoryButton.tap()
        
        let automobilesButton = app.buttons["Automobiles"]
        XCTAssertTrue(waitForElementWithRetry(automobilesButton, timeout: 5, retries: 3))
        automobilesButton.tap()
        
        let carButton = app.buttons["Car"]
        XCTAssertTrue(waitForElementWithRetry(carButton, timeout: 5, retries: 3))
        carButton.tap()
        
        let sportsCarButton = app.buttons["Sports Car"]
        XCTAssertTrue(waitForElementWithRetry(sportsCarButton, timeout: 5, retries: 3))
        sportsCarButton.tap()
        
        // Add trim level with retries
        let trimField = app.textFields["Trim Level"]
        XCTAssertTrue(waitForElementWithRetry(trimField, timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTypeText("GT", into: trimField))
        
        // Save with retries
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(waitForElementWithRetry(saveButton, timeout: 5, retries: 3))
        saveButton.tap()
        
        // Wait for navigation and verify vehicle with retries
        XCTAssertTrue(waitForNavigationBar())
        
        // The vehicle name could be displayed in different formats depending on the group option
        let possibleNames = [
            "2023 Ford Mustang (Sally)",  // No grouping
            "Ford Mustang (Sally)",       // Year grouping
            "2023 Mustang (Sally)",       // Make grouping
            "2023 Ford Mustang (Sally)"   // Category grouping
        ]
        
        var vehicleFound = false
        for name in possibleNames {
            let vehicleCell = app.staticTexts[name]
            if waitForElementWithRetry(vehicleCell, timeout: 5, retries: 3) {
                vehicleFound = true
                break
            }
        }
        
        XCTAssertTrue(vehicleFound, "Vehicle should appear in the list with one of the expected formats")
    }
    
    // MARK: - Sort and Filter Tests
    
    func testSortMenuExists() throws {
        // Navigate to settings with retries
        XCTAssertTrue(waitForElementWithRetry(app.buttons["Settings"], timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTapButton("Settings"))
        
        // Wait for settings view to load
        XCTAssertTrue(waitForElementWithRetry(app.navigationBars["Settings"], timeout: 5, retries: 3))
        
        // Verify appearance section exists
        let appearanceHeader = app.staticTexts["APPEARANCE"]
        XCTAssertTrue(waitForElementWithRetry(appearanceHeader, timeout: 5, retries: 3))
        
        // Tap the sort picker
        let sortPicker = app.cells["Sort Vehicles By"]
        XCTAssertTrue(waitForElementWithRetry(sortPicker, timeout: 5, retries: 3))
        sortPicker.tap()
        
        // Test each sort option
        let sortOptions = ["None", "Year", "Make", "Last Updated", "Category"]
        for option in sortOptions {
            let pickerWheel = app.pickerWheels.firstMatch
            XCTAssertTrue(waitForElementWithRetry(pickerWheel, timeout: 5, retries: 3))
            pickerWheel.adjust(toPickerWheelValue: option)
            // Add a small delay to let the picker settle
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Dismiss settings and verify return to main view
        XCTAssertTrue(waitForAndTapButton("Done"))
        XCTAssertTrue(waitForNavigationBar())
    }
    
    func testGroupMenuExists() throws {
        // Navigate to settings with retries
        XCTAssertTrue(waitForElementWithRetry(app.buttons["Settings"], timeout: 5, retries: 3))
        XCTAssertTrue(waitForAndTapButton("Settings"))
        
        // Wait for settings view to load
        XCTAssertTrue(waitForElementWithRetry(app.navigationBars["Settings"], timeout: 5, retries: 3))
        
        // Verify appearance section exists
        let appearanceHeader = app.staticTexts["APPEARANCE"]
        XCTAssertTrue(waitForElementWithRetry(appearanceHeader, timeout: 5, retries: 3))
        
        // Tap the group picker
        let groupPicker = app.cells["Group Vehicles By"]
        XCTAssertTrue(waitForElementWithRetry(groupPicker, timeout: 5, retries: 3))
        groupPicker.tap()
        
        // Test each group option
        let groupOptions = ["None", "Category", "Make", "Year"]
        for option in groupOptions {
            let pickerWheel = app.pickerWheels.firstMatch
            XCTAssertTrue(waitForElementWithRetry(pickerWheel, timeout: 5, retries: 3))
            pickerWheel.adjust(toPickerWheelValue: option)
            // Add a small delay to let the picker settle
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Dismiss settings and verify return to main view
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
        
        // Wait for and tap the search field
        let searchField = app.searchFields["Search vehicles, events, and records"]
        XCTAssertTrue(waitForElementWithRetry(searchField, timeout: 5, retries: 3))
        searchField.tap()
        
        // Type the search text with retry
        XCTAssertTrue(waitForAndTypeText("Toyota", into: searchField))
        
        // The vehicle name could be displayed in different formats depending on the group option
        let currentYear = Calendar.current.component(.year, from: Date())
        let possibleNames = [
            "\(currentYear) Toyota Camry",  // No grouping
            "Toyota Camry",                 // Year grouping
            "\(currentYear) Camry",         // Make grouping
            "\(currentYear) Toyota Camry"   // Category grouping
        ]
        
        // Wait for search results with retries
        var vehicleFound = false
        for name in possibleNames {
            let vehicleCell = app.staticTexts[name]
            if waitForElementWithRetry(vehicleCell, timeout: 5, retries: 3) {
                vehicleFound = true
                break
            }
        }
        XCTAssertTrue(vehicleFound, "Vehicle should appear in search results with one of the expected formats")
        
        // Clear search and verify
        XCTAssertTrue(clearSearchField())
        
        // Search for non-existent vehicle with retries
        XCTAssertTrue(waitForElementWithRetry(searchField, timeout: 5, retries: 3))
        searchField.tap()
        XCTAssertTrue(waitForAndTypeText("Honda", into: searchField))
        
        // Wait for no results message with retries
        let noResultsMessage = app.staticTexts["No Results"]
        XCTAssertTrue(waitForElementWithRetry(noResultsMessage, timeout: 5, retries: 3))
        
        // Clean up by clearing search
        XCTAssertTrue(clearSearchField())
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Configure measurement options
            let options = XCTMeasureOptions()
            options.invocationOptions = [.manuallyStart]
            
            measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
                // Ensure app is terminated before each iteration
                let app = XCUIApplication()
                app.terminate()
                
                // Configure app for testing
                app.launchArguments = ["UI-Testing"]
                app.launchEnvironment = ["UITESTING": "1"]
                
                // Start measurement and launch
                startMeasuring()
                app.launch()
                
                // Wait for app to be fully loaded
                let navBar = app.navigationBars["Vehicles"]
                let exists = navBar.waitForExistence(timeout: 15)
                
                if !exists {
                    // Take a screenshot to help debug failures
                    let screenshot = XCUIScreen.main.screenshot()
                    let attachment = XCTAttachment(screenshot: screenshot)
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
                
                // Verify app loaded successfully
                XCTAssertTrue(exists, "App failed to load within timeout")
                
                // Stop measuring after we've verified the app is loaded
                stopMeasuring()
                
                // Clean up
                app.terminate()
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
