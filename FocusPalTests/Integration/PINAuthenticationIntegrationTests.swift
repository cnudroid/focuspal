//
//  PINAuthenticationIntegrationTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Integration tests for the complete PIN authentication flow
@MainActor
final class PINAuthenticationIntegrationTests: XCTestCase {

    var pinService: PINService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        pinService = PINService()
        pinService.resetPin()
    }

    override func tearDownWithError() throws {
        pinService.resetPin()
        pinService = nil
        try super.tearDownWithError()
    }

    // MARK: - First Time Setup Flow

    func testFirstTimeSetupFlow() async {
        // Arrange: User opens app for first time
        let setupViewModel = PINSetupViewModel(pinService: pinService)
        XCTAssertFalse(pinService.isPinSet(), "PIN should not be set initially")

        // Act: User enters PIN
        setupViewModel.addDigit(1)
        setupViewModel.addDigit(2)
        setupViewModel.addDigit(3)
        setupViewModel.addDigit(4)

        // Assert: Moved to confirm step
        XCTAssertEqual(setupViewModel.step, .confirmPin, "Should move to confirm step")

        // Act: User confirms PIN
        setupViewModel.addDigit(1)
        setupViewModel.addDigit(2)
        setupViewModel.addDigit(3)
        setupViewModel.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: PIN is saved and setup complete
        XCTAssertTrue(setupViewModel.isComplete, "Setup should be complete")
        XCTAssertTrue(pinService.isPinSet(), "PIN should be saved")
        XCTAssertTrue(pinService.verifyPin(pin: "1234"), "PIN should be verifiable")
    }

    // MARK: - Authentication Flow

    func testSuccessfulAuthenticationFlow() async {
        // Arrange: PIN is already set
        try? pinService.savePin(pin: "1234")
        let authViewModel = ParentAuthViewModel(pinService: pinService)

        // Act: User enters correct PIN
        authViewModel.addDigit(1)
        authViewModel.addDigit(2)
        authViewModel.addDigit(3)
        authViewModel.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: User is authenticated
        XCTAssertTrue(authViewModel.isAuthenticated, "User should be authenticated")
        XCTAssertEqual(authViewModel.failedAttempts, 0, "Failed attempts should be 0")
    }

    func testFailedAuthenticationFlow() async {
        // Arrange: PIN is set
        try? pinService.savePin(pin: "1234")
        let authViewModel = ParentAuthViewModel(pinService: pinService)

        // Act: User enters wrong PIN
        authViewModel.addDigit(5)
        authViewModel.addDigit(6)
        authViewModel.addDigit(7)
        authViewModel.addDigit(8)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: Authentication failed
        XCTAssertFalse(authViewModel.isAuthenticated, "User should not be authenticated")
        XCTAssertEqual(authViewModel.failedAttempts, 1, "Should have 1 failed attempt")
        XCTAssertTrue(authViewModel.shouldShake, "Should trigger shake animation")
    }

    func testLockoutFlow() async {
        // Arrange: PIN is set
        try? pinService.savePin(pin: "1234")
        let authViewModel = ParentAuthViewModel(pinService: pinService)

        // Act: User enters wrong PIN 3 times
        for _ in 0..<3 {
            authViewModel.addDigit(9)
            authViewModel.addDigit(9)
            authViewModel.addDigit(9)
            authViewModel.addDigit(9)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Assert: User is locked out
        XCTAssertEqual(authViewModel.failedAttempts, 3, "Should have 3 failed attempts")
        XCTAssertTrue(authViewModel.isLockedOut, "User should be locked out")
        XCTAssertNotNil(authViewModel.lockoutEndTime, "Lockout end time should be set")
        XCTAssertGreaterThan(authViewModel.remainingLockoutTime, 0, "Should have remaining lockout time")

        // Act: Try to enter PIN during lockout
        let pinBeforeLockout = authViewModel.enteredPin
        authViewModel.addDigit(1)

        // Assert: Cannot enter digits during lockout
        XCTAssertEqual(authViewModel.enteredPin, pinBeforeLockout, "Should not accept digits during lockout")
    }

    // MARK: - PIN Change Flow

    func testPINChangeFlow() async {
        // Arrange: Old PIN is set
        try? pinService.savePin(pin: "1234")
        let changeViewModel = PINChangeViewModel(pinService: pinService)

        // Act: Verify old PIN
        changeViewModel.addDigit(1)
        changeViewModel.addDigit(2)
        changeViewModel.addDigit(3)
        changeViewModel.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: Moved to enter new PIN step
        XCTAssertEqual(changeViewModel.step, .enterNew, "Should move to enter new step")

        // Act: Enter new PIN
        changeViewModel.addDigit(5)
        changeViewModel.addDigit(6)
        changeViewModel.addDigit(7)
        changeViewModel.addDigit(8)

        // Assert: Moved to confirm step
        XCTAssertEqual(changeViewModel.step, .confirmNew, "Should move to confirm step")

        // Act: Confirm new PIN
        changeViewModel.addDigit(5)
        changeViewModel.addDigit(6)
        changeViewModel.addDigit(7)
        changeViewModel.addDigit(8)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: PIN changed successfully
        XCTAssertTrue(changeViewModel.isComplete, "Change should be complete")
        XCTAssertTrue(pinService.verifyPin(pin: "5678"), "New PIN should be set")
        XCTAssertFalse(pinService.verifyPin(pin: "1234"), "Old PIN should not work")
    }

    // MARK: - Error Handling

    func testPINSetupMismatch() async {
        // Arrange
        let setupViewModel = PINSetupViewModel(pinService: pinService)

        // Act: Enter PIN
        setupViewModel.addDigit(1)
        setupViewModel.addDigit(2)
        setupViewModel.addDigit(3)
        setupViewModel.addDigit(4)

        // Act: Confirm with different PIN
        setupViewModel.addDigit(5)
        setupViewModel.addDigit(6)
        setupViewModel.addDigit(7)
        setupViewModel.addDigit(8)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: Error shown and PIN not saved
        XCTAssertFalse(setupViewModel.isComplete, "Setup should not be complete")
        XCTAssertNotNil(setupViewModel.errorMessage, "Should show error message")
        XCTAssertFalse(pinService.isPinSet(), "PIN should not be saved")
    }

    func testPINChangeSameAsOld() async {
        // Arrange: Set initial PIN
        try? pinService.savePin(pin: "1234")
        let changeViewModel = PINChangeViewModel(pinService: pinService)

        // Navigate through steps with same PIN
        changeViewModel.addDigit(1)
        changeViewModel.addDigit(2)
        changeViewModel.addDigit(3)
        changeViewModel.addDigit(4)
        try? await Task.sleep(nanoseconds: 100_000_000)

        changeViewModel.addDigit(1)
        changeViewModel.addDigit(2)
        changeViewModel.addDigit(3)
        changeViewModel.addDigit(4)

        changeViewModel.addDigit(1)
        changeViewModel.addDigit(2)
        changeViewModel.addDigit(3)
        changeViewModel.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: Error shown and PIN not changed
        XCTAssertFalse(changeViewModel.isComplete, "Change should not be complete")
        XCTAssertNotNil(changeViewModel.errorMessage, "Should show error message")
        XCTAssertTrue(changeViewModel.errorMessage?.contains("different") ?? false)
    }
}
