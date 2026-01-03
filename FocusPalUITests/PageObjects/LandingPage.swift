//
//  LandingPage.swift
//  FocusPalUITests
//
//  Page Object for Landing screen (when no children exist)
//

import XCTest

class LandingPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var welcomeTitle: XCUIElement {
        app.staticTexts["Welcome!"]
    }

    var emptyStateMessage: XCUIElement {
        app.staticTexts["Let's create your first child profile"]
    }

    var addChildButton: XCUIElement {
        app.buttons["Add Child Profile"]
    }

    var settingsButton: XCUIElement {
        app.buttons["Settings"]
    }

    // MARK: - Actions

    func tapAddChild() {
        addChildButton.tap()
    }

    func tapSettings() {
        settingsButton.tap()
    }

    // MARK: - Verification

    func verifyLandingScreen() {
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2), "Welcome title should be visible")
        XCTAssertTrue(addChildButton.exists, "Add child button should be visible")
    }
}
