//
//  AnchorUITests.swift
//  AnchorUITests
//
//  Created by Mohammad Elhaj on 07/02/2026.
//

import XCTest

final class AnchorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunches() throws {
        // Test that the app launches successfully
        let app = XCUIApplication()
        app.launch()
        
        // Verify home screen elements are present
        XCTAssertTrue(app.staticTexts["Welcome to Anchor"].exists)
        XCTAssertTrue(app.staticTexts["Your private emotional support companion"].exists)
    }
    
    @MainActor
    func testStartConversationButton() throws {
        // Test that start conversation button exists and is tappable
        let app = XCUIApplication()
        app.launch()
        
        let startButton = app.buttons["Start Conversation"]
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(startButton.isEnabled)
    }
    
    @MainActor
    func testNavigationToSettings() throws {
        // Test navigation to settings
        let app = XCUIApplication()
        app.launch()
        
        // Look for settings button in navigation bar
        let settingsButton = app.buttons.matching(identifier: "gearshape").firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // Verify settings view opened
            XCTAssertTrue(app.navigationBars["Settings"].exists || app.staticTexts["Settings"].exists)
        }
    }
    
    @MainActor
    func testNavigationToHistory() throws {
        // Test navigation to history
        let app = XCUIApplication()
        app.launch()
        
        // Look for history button in navigation bar
        let historyButton = app.buttons.matching(identifier: "clock.arrow.circlepath").firstMatch
        if historyButton.exists {
            historyButton.tap()
            
            // Verify history view opened
            XCTAssertTrue(app.navigationBars["History"].exists || app.staticTexts["No sessions yet"].exists)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
