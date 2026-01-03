//
//  BaseUITest.swift
//  FocusPalUITests
//
//  Base class for all UI tests with common setup, teardown, and utilities
//

import XCTest

class BaseUITest: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launchEnvironment = [
            "UITEST_DISABLE_ANIMATIONS": "1",
            "UITEST_RESET_DATA": "1"
        ]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Launch Helpers

    /// Launch app in fresh state (onboarding not completed)
    func launchFreshApp() {
        app.launchEnvironment["UITEST_FRESH_INSTALL"] = "1"
        app.launch()
    }

    /// Launch app with onboarding completed but no child profiles
    func launchWithOnboardingComplete() {
        app.launchEnvironment["UITEST_ONBOARDING_COMPLETE"] = "1"
        app.launch()
    }

    /// Launch app with single child profile
    func launchWithSingleChild(name: String = "Emma", age: Int = 8) {
        app.launchEnvironment["UITEST_SINGLE_CHILD"] = "1"
        app.launchEnvironment["UITEST_CHILD_NAME"] = name
        app.launchEnvironment["UITEST_CHILD_AGE"] = "\(age)"
        app.launch()
    }

    /// Launch app with multiple child profiles
    func launchWithMultipleChildren(count: Int = 3) {
        app.launchEnvironment["UITEST_MULTIPLE_CHILDREN"] = "1"
        app.launchEnvironment["UITEST_CHILD_COUNT"] = "\(count)"
        app.launch()
    }

    /// Launch app with sample activity data
    func launchWithSampleData() {
        app.launchEnvironment["UITEST_SAMPLE_DATA"] = "1"
        app.launch()
    }

    // MARK: - Wait Helpers

    /// Wait for element to exist with timeout
    @discardableResult
    func wait(for element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for element to not exist with timeout
    @discardableResult
    func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for element to be hittable (visible and tappable)
    @discardableResult
    func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    // MARK: - Interaction Helpers

    /// Tap element after waiting for it to be hittable
    func tapWhenHittable(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(waitUntilHittable(element, timeout: timeout), "Element not hittable: \(element)")
        element.tap()
    }

    /// Type text into element after clearing existing text
    func clearAndType(text: String, into element: XCUIElement) {
        element.tap()

        // Select all and delete
        if let currentValue = element.value as? String, !currentValue.isEmpty {
            element.tap()
            element.press(forDuration: 1.0)
            app.menuItems["Select All"].tap()
            app.keys["delete"].tap()
        }

        element.typeText(text)
    }

    /// Scroll to element if not visible
    func scrollTo(_ element: XCUIElement, in scrollView: XCUIElement) {
        while !element.isHittable && scrollView.exists {
            scrollView.swipeUp()
        }
    }

    // MARK: - Assertion Helpers

    /// Assert element exists and is visible
    func assertExists(_ element: XCUIElement, message: String? = nil) {
        XCTAssertTrue(element.exists, message ?? "Element should exist: \(element)")
    }

    /// Assert element does not exist
    func assertNotExists(_ element: XCUIElement, message: String? = nil) {
        XCTAssertFalse(element.exists, message ?? "Element should not exist: \(element)")
    }

    /// Assert element contains text
    func assertContainsText(_ element: XCUIElement, text: String) {
        if let label = element.label as String? {
            XCTAssertTrue(label.contains(text), "Element label '\(label)' should contain '\(text)'")
        } else if let value = element.value as? String {
            XCTAssertTrue(value.contains(text), "Element value '\(value)' should contain '\(text)'")
        } else {
            XCTFail("Element has no text content")
        }
    }

    // MARK: - Screenshot Helpers

    /// Take screenshot with custom name
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - PIN Entry Helper

    /// Enter 4-digit PIN
    func enterPIN(_ pin: String, using app: XCUIApplication) {
        XCTAssertEqual(pin.count, 4, "PIN must be 4 digits")

        for digit in pin {
            let button = app.buttons[String(digit)]
            XCTAssertTrue(button.waitForExistence(timeout: 2), "PIN digit button \(digit) not found")
            button.tap()
        }
    }

    // MARK: - Navigation Helpers

    /// Navigate back using navigation bar back button
    func navigateBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// Navigate to tab
    func navigateToTab(_ tabName: String) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar not found")

        let tab = tabBar.buttons[tabName]
        XCTAssertTrue(tab.exists, "Tab '\(tabName)' not found")
        tab.tap()
    }

    // MARK: - Date/Time Helpers

    /// Fast-forward timer for testing (requires test hook)
    func fastForwardTimer(seconds: Int) {
        app.buttons["FastForwardTimer"].tap()

        // In real implementation, this would trigger a test hook
        // that advances the timer's internal state
        sleep(UInt32(seconds))
    }

    // MARK: - Accessibility Testing Helpers

    /// Verify element has accessibility label
    func assertHasAccessibilityLabel(_ element: XCUIElement, message: String? = nil) {
        XCTAssertFalse(element.label.isEmpty, message ?? "Element should have accessibility label")
    }

    /// Verify screen is navigable with VoiceOver
    func assertVoiceOverNavigable(screen: XCUIElement) {
        // This is a simplified check - full VoiceOver testing requires more setup
        let accessibleElements = screen.descendants(matching: .any).allElementsBoundByIndex.filter { element in
            element.isHittable && !element.label.isEmpty
        }

        XCTAssertGreaterThan(accessibleElements.count, 0, "Screen should have accessible elements for VoiceOver")
    }

    // MARK: - Performance Helpers

    /// Measure performance of a block
    func measurePerformance(identifier: String, block: () -> Void) {
        measure(metrics: [XCTClockMetric()], options: XCTMeasureOptions()) {
            block()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {

    /// Check if element is visible on screen
    var isVisible: Bool {
        return exists && isHittable
    }

    /// Get element's text (label or value)
    var text: String? {
        if let label = label as String?, !label.isEmpty {
            return label
        }
        return value as? String
    }

    /// Tap element forcefully (even if not hittable)
    func forceTap() {
        if isHittable {
            tap()
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
