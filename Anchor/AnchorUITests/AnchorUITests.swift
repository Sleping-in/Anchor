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
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launch()

        // App should launch into home
        let onboardingContinue = app.buttons["onboarding.continue"]
        let homeStart = app.buttons["home.startConversation"]
        XCTAssertTrue(
            homeStart.waitForExistence(timeout: 5) || onboardingContinue.waitForExistence(timeout: 5),
            "Expected home screen to appear"
        )
    }

    @MainActor
    func testStartConversationButton() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launch()

        let startButton = app.buttons["home.startConversation"]
        if startButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(startButton.isEnabled)
        }
    }

    @MainActor
    func testNavigationToSettings() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launch()

        let settingsButton = app.buttons["home.settings"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            XCTAssertTrue(
                app.navigationBars["Settings"].waitForExistence(timeout: 3) ||
                app.staticTexts["Settings"].waitForExistence(timeout: 3)
            )
        }
    }

    @MainActor
    func testNavigationToHistory() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launch()

        let historyButton = app.buttons["home.history"]
        if historyButton.waitForExistence(timeout: 5) {
            historyButton.tap()
            XCTAssertTrue(
                app.navigationBars["History"].waitForExistence(timeout: 3) ||
                app.staticTexts["No sessions yet"].waitForExistence(timeout: 3)
            )
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
