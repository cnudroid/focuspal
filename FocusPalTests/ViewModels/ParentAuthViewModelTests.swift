//
//  ParentAuthViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for ParentAuthViewModel - manages parent authentication state and lockout
@MainActor
final class ParentAuthViewModelTests: XCTestCase {

    var sut: ParentAuthViewModel!
    var mockPinService: SharedMockPINService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPinService = SharedMockPINService()
        sut = ParentAuthViewModel(pinService: mockPinService)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockPinService = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_SetsCorrectInitialState() {
        // Assert
        XCTAssertEqual(sut.enteredPin, "", "Initial entered PIN should be empty")
        XCTAssertEqual(sut.failedAttempts, 0, "Initial failed attempts should be 0")
        XCTAssertFalse(sut.isLockedOut, "Should not be locked out initially")
        XCTAssertNil(sut.lockoutEndTime, "Lockout end time should be nil initially")
        XCTAssertFalse(sut.isAuthenticated, "Should not be authenticated initially")
        XCTAssertFalse(sut.shouldShake, "Should not shake initially")
    }

    // MARK: - isPinSetup Tests

    func testIsPinSetup_WhenPinIsSet_ReturnsTrue() {
        // Arrange
        mockPinService.isPinSetValue = true

        // Act
        let result = sut.isPinSetup

        // Assert
        XCTAssertTrue(result, "isPinSetup should return true when PIN is set")
    }

    func testIsPinSetup_WhenPinNotSet_ReturnsFalse() {
        // Arrange
        mockPinService.isPinSetValue = false

        // Act
        let result = sut.isPinSetup

        // Assert
        XCTAssertFalse(result, "isPinSetup should return false when PIN is not set")
    }

    // MARK: - addDigit Tests

    func testAddDigit_WhenLessThanFourDigits_AddsDigit() {
        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)

        // Assert
        XCTAssertEqual(sut.enteredPin, "123", "Should add digits to entered PIN")
    }

    func testAddDigit_WhenFourDigitsAlready_DoesNotAddMore() {
        // Arrange
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        // Act
        sut.addDigit(5)

        // Assert
        XCTAssertEqual(sut.enteredPin, "1234", "Should not add more than 4 digits")
    }

    func testAddDigit_WhenLockedOut_DoesNotAddDigit() {
        // Arrange: Set lockout
        sut.failedAttempts = 3
        sut.lockoutEndTime = Date().addingTimeInterval(30)

        // Act
        sut.addDigit(1)

        // Assert
        XCTAssertEqual(sut.enteredPin, "", "Should not add digit when locked out")
    }

    func testAddDigit_FourthDigit_AutomaticallyVerifiesPin() async {
        // Arrange
        mockPinService.verifyPinReturnValue = true

        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        // Small delay for async verification
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertTrue(sut.isAuthenticated, "Should automatically verify after 4th digit")
    }

    // MARK: - deleteDigit Tests

    func testDeleteDigit_RemovesLastDigit() {
        // Arrange
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)

        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.enteredPin, "12", "Should remove last digit")
    }

    func testDeleteDigit_WhenEmpty_DoesNothing() {
        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.enteredPin, "", "Should remain empty")
    }

    // MARK: - verifyPin Tests

    func testVerifyPin_WithCorrectPin_AuthenticatesSuccessfully() async {
        // Arrange
        mockPinService.verifyPinReturnValue = true
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        // Act
        await sut.verifyPin()

        // Assert
        XCTAssertTrue(sut.isAuthenticated, "Should be authenticated with correct PIN")
        XCTAssertEqual(sut.failedAttempts, 0, "Failed attempts should be reset")
        XCTAssertEqual(sut.enteredPin, "", "PIN should be cleared after success")
    }

    func testVerifyPin_WithIncorrectPin_IncrementsFailedAttempts() async {
        // Arrange
        mockPinService.verifyPinReturnValue = false
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        // Act
        await sut.verifyPin()

        // Assert
        XCTAssertFalse(sut.isAuthenticated, "Should not be authenticated with wrong PIN")
        XCTAssertEqual(sut.failedAttempts, 1, "Failed attempts should increment")
        XCTAssertEqual(sut.enteredPin, "", "PIN should be cleared after failed attempt")
        XCTAssertTrue(sut.shouldShake, "Should trigger shake animation")
    }

    func testVerifyPin_ThirdFailedAttempt_TriggersLockout() async {
        // Arrange
        mockPinService.verifyPinReturnValue = false
        sut.failedAttempts = 2

        // Act
        for _ in 0..<4 {
            sut.addDigit(1)
        }
        await sut.verifyPin()

        // Assert
        XCTAssertEqual(sut.failedAttempts, 3, "Should have 3 failed attempts")
        XCTAssertTrue(sut.isLockedOut, "Should be locked out after 3 failures")
        XCTAssertNotNil(sut.lockoutEndTime, "Lockout end time should be set")
    }

    func testVerifyPin_DuringLockout_DoesNotVerify() async {
        // Arrange
        sut.failedAttempts = 3
        sut.lockoutEndTime = Date().addingTimeInterval(30)
        mockPinService.verifyPinReturnValue = true

        // Act
        for _ in 0..<4 {
            sut.addDigit(1)
        }
        await sut.verifyPin()

        // Assert
        XCTAssertFalse(sut.isAuthenticated, "Should not authenticate during lockout")
        XCTAssertFalse(mockPinService.verifyPinCalled, "Should not call verify during lockout")
    }

    // MARK: - Lockout Tests

    func testIsLockedOut_WithActiveLockout_ReturnsTrue() {
        // Arrange
        sut.lockoutEndTime = Date().addingTimeInterval(30)

        // Act
        let result = sut.isLockedOut

        // Assert
        XCTAssertTrue(result, "Should be locked out when lockout time is in future")
    }

    func testIsLockedOut_WithExpiredLockout_ReturnsFalse() {
        // Arrange
        sut.lockoutEndTime = Date().addingTimeInterval(-1)

        // Act
        let result = sut.isLockedOut

        // Assert
        XCTAssertFalse(result, "Should not be locked out when lockout time has passed")
    }

    func testRemainingLockoutTime_DuringLockout_ReturnsCorrectTime() {
        // Arrange
        let lockoutDuration: TimeInterval = 30
        sut.lockoutEndTime = Date().addingTimeInterval(lockoutDuration)

        // Act
        let remaining = sut.remainingLockoutTime

        // Assert
        XCTAssertGreaterThan(remaining, 0, "Remaining time should be positive")
        XCTAssertLessThanOrEqual(remaining, lockoutDuration, "Remaining time should not exceed lockout duration")
    }

    func testRemainingLockoutTime_WithNoLockout_ReturnsZero() {
        // Arrange
        sut.lockoutEndTime = nil

        // Act
        let remaining = sut.remainingLockoutTime

        // Assert
        XCTAssertEqual(remaining, 0, "Remaining time should be 0 when not locked out")
    }

    // MARK: - Shake Animation Tests

    func testResetShake_ClearsShakeState() async {
        // Arrange
        sut.shouldShake = true

        // Act
        await sut.resetShake()

        // Assert
        XCTAssertFalse(sut.shouldShake, "Shake state should be reset")
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllState() {
        // Arrange
        sut.enteredPin = "1234"
        sut.failedAttempts = 2
        sut.isAuthenticated = true
        sut.shouldShake = true

        // Act
        sut.reset()

        // Assert
        XCTAssertEqual(sut.enteredPin, "", "Entered PIN should be cleared")
        XCTAssertEqual(sut.failedAttempts, 0, "Failed attempts should be reset")
        XCTAssertFalse(sut.isAuthenticated, "Should not be authenticated")
        XCTAssertFalse(sut.shouldShake, "Shake state should be reset")
    }
}

