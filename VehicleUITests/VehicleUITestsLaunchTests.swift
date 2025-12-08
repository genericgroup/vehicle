//
//  VehicleUITestsLaunchTests.swift
//  VehicleUITests
//
//  Created by Andy Carlson on 1/20/25.
//

import XCTest

final class VehicleUITestsLaunchTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    // MARK: - Launch Tests

    @MainActor
    func testLaunchToVehiclesList() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify we launch to the vehicles list
        let vehiclesNavBar = app.navigationBars["Vehicles"]
        XCTAssertTrue(vehiclesNavBar.exists)
        
        // Take a screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Vehicles List"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchWithEmptyState() throws {
        // Verify navigation bar exists
        XCTAssertTrue(app.navigationBars["Vehicles"].exists)
        
        // Verify empty state view exists
        let emptyStateView = app.staticTexts["No Vehicles"]
        XCTAssertTrue(emptyStateView.exists)
        
        // Verify empty state description
        let description = app.staticTexts["Add your first vehicle to get started"]
        XCTAssertTrue(description.exists)
        
        // Verify Add Menu button exists
        XCTAssertTrue(app.buttons["Add Menu"].exists)
        
        // Verify Settings button exists
        XCTAssertTrue(app.buttons["Settings"].exists)
        
        // Verify search field exists
        let searchField = app.searchFields["Search vehicles, events, and records"]
        XCTAssertTrue(searchField.exists)
    }
    
    @MainActor
    func testLaunchNavigationElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify core navigation elements exist with correct accessibility identifiers
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.buttons["Add Menu"].exists)
        XCTAssertTrue(app.searchFields["Search vehicles, events, and records"].exists)
        
        // Take a screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Navigation Elements"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
