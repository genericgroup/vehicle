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
        
        // Terminate any existing instance first
        app = XCUIApplication()
        app.terminate()
        
        // Configure and launch fresh
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UITESTING": "1"]
        app.launch()
        
        // Wait for app to be ready with longer timeout
        let addButton = app.buttons["Add Menu"]
        if !addButton.waitForExistence(timeout: 60) {
            // Take screenshot for debugging
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("App failed to launch - Add Menu button not found after 60s")
        }
    }
    
    override func tearDownWithError() throws {
        // Terminate app to ensure clean state for next test
        app?.terminate()
        app = nil
    }
    
    // MARK: - Basic Tests
    
    func testAppLaunches() throws {
        // If we got here, setup passed - app launched successfully
        XCTAssertTrue(app.buttons["Add Menu"].exists, "Add Menu button should exist")
    }
    
    func testSettingsButtonExists() throws {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "Settings button should exist")
    }
}
