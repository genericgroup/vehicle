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
    }
    
    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }
    
    // MARK: - Basic Tests
    
    /// Test that the app launches without crashing
    func testAppLaunches() throws {
        app.launch()
        
        // Just verify the app is running - don't look for specific elements
        // The app state should be "running" after launch
        XCTAssertEqual(app.state, .runningForeground, "App should be running in foreground")
        
        // Take a screenshot to see what's on screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "App Launch Screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
