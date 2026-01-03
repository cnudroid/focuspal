//
//  OnboardingPage.swift
//  FocusPalUITests
//
//  Page Object for Onboarding screens
//

import XCTest

class OnboardingPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Welcome Screen Elements

    var welcomeTitle: XCUIElement {
        app.staticTexts["Welcome to FocusPal"]
    }

    var welcomeSubtitle: XCUIElement {
        app.staticTexts["An ADHD-friendly timer and activity tracker"]
    }

    var getStartedButton: XCUIElement {
        app.buttons["Get Started"]
    }

    // MARK: - PIN Setup Screen Elements

    var pinSetupTitle: XCUIElement {
        app.staticTexts["Create Parent PIN"]
    }

    var pinSetupInstructions: XCUIElement {
        app.staticTexts["Create a 4-digit PIN to protect parent controls"]
    }

    func pinDigitButton(_ digit: String) -> XCUIElement {
        app.buttons[digit]
    }

    var pinDeleteButton: XCUIElement {
        app.buttons["Delete"]
    }

    var pinDotsDisplay: XCUIElement {
        app.otherElements["PINDotsDisplay"]
    }

    var pinConfirmationTitle: XCUIElement {
        app.staticTexts["Confirm Your PIN"]
    }

    var pinMismatchError: XCUIElement {
        app.staticTexts["PINs do not match. Please try again."]
    }

    // MARK: - Permissions Screen Elements

    var permissionsTitle: XCUIElement {
        app.staticTexts["Enable Notifications"]
    }

    var permissionsDescription: XCUIElement {
        app.staticTexts["Get notified when timers complete and achievements unlock"]
    }

    var enableNotificationsButton: XCUIElement {
        app.buttons["Enable Notifications"]
    }

    var skipButton: XCUIElement {
        app.buttons["Skip"]
    }

    var finishButton: XCUIElement {
        app.buttons["Finish"]
    }

    // MARK: - Navigation Elements

    var nextButton: XCUIElement {
        app.buttons["Next"]
    }

    var backButton: XCUIElement {
        app.navigationBars.buttons.element(boundBy: 0)
    }

    var progressIndicator: XCUIElement {
        app.otherElements["OnboardingProgress"]
    }

    // MARK: - Actions

    func tapGetStarted() {
        getStartedButton.tap()
    }

    func enterPIN(_ pin: String) {
        XCTAssertEqual(pin.count, 4, "PIN must be 4 digits")

        for digit in pin {
            pinDigitButton(String(digit)).tap()
        }
    }

    func deletePINDigit() {
        pinDeleteButton.tap()
    }

    func tapNext() {
        nextButton.tap()
    }

    func tapBack() {
        backButton.tap()
    }

    func tapEnableNotifications() {
        enableNotificationsButton.tap()
    }

    func tapSkip() {
        skipButton.tap()
    }

    func tapFinish() {
        finishButton.tap()
    }

    // MARK: - Verification Methods

    func verifyWelcomeScreen() {
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2), "Welcome title should be visible")
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be visible")
    }

    func verifyPINSetupScreen() {
        XCTAssertTrue(pinSetupTitle.waitForExistence(timeout: 2), "PIN setup title should be visible")
        XCTAssertTrue(pinDigitButton("1").exists, "PIN digit buttons should be visible")
    }

    func verifyPINConfirmationScreen() {
        XCTAssertTrue(pinConfirmationTitle.waitForExistence(timeout: 2), "PIN confirmation title should be visible")
    }

    func verifyPermissionsScreen() {
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 2), "Permissions title should be visible")
        XCTAssertTrue(enableNotificationsButton.exists, "Enable notifications button should be visible")
    }

    func verifyPINMismatchError() {
        XCTAssertTrue(pinMismatchError.waitForExistence(timeout: 2), "PIN mismatch error should be displayed")
    }

    // MARK: - Complete Flow

    func completeOnboarding(pin: String = "1234") {
        // Step 1: Welcome
        verifyWelcomeScreen()
        tapGetStarted()

        // Step 2: Create PIN
        verifyPINSetupScreen()
        enterPIN(pin)

        // Step 3: Confirm PIN
        verifyPINConfirmationScreen()
        enterPIN(pin)

        // Step 4: Permissions
        verifyPermissionsScreen()
        tapFinish()
    }
}
