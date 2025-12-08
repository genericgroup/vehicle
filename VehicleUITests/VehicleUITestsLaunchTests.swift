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
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // Disabled - runs tests multiple times for each UI configuration (slow)
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    // MARK: - Launch Tests

    func testLaunchToVehiclesList() throws {
        // Verify we launch to the vehicles list
        XCTAssertTrue(app.navigationBars["Vehicles"].waitForExistence(timeout: 10))
    }
    
    func testLaunchWithEmptyState() throws {
        // Verify navigation bar and empty state
        XCTAssertTrue(app.navigationBars["Vehicles"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["No Vehicles"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add Menu"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }
    
    func testLaunchNavigationElements() throws {
        // Verify core navigation elements exist
        XCTAssertTrue(app.navigationBars["Vehicles"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.buttons["Add Menu"].exists)
        XCTAssertTrue(app.searchFields["Search vehicles, events, and records"].exists)
    }

    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
