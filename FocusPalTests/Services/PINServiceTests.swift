//
//  PINServiceTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for PINService - secure PIN storage and verification using Keychain
final class PINServiceTests: XCTestCase {

    var sut: PINService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = PINService()
        // Clean up any existing PIN from previous tests
        sut.resetPin()
    }

    override func tearDownWithError() throws {
        sut.resetPin()
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - isPinSet Tests

    func testIsPinSet_WhenNoPinSaved_ReturnsFalse() {
        // Arrange: Fresh instance with no PIN saved

        // Act
        let result = sut.isPinSet()

        // Assert
        XCTAssertFalse(result, "isPinSet should return false when no PIN has been saved")
    }

    func testIsPinSet_AfterSavingPin_ReturnsTrue() {
        // Arrange
        let pin = "1234"

        // Act
        try? sut.savePin(pin: pin)
        let result = sut.isPinSet()

        // Assert
        XCTAssertTrue(result, "isPinSet should return true after a PIN has been saved")
    }

    // MARK: - savePin Tests

    func testSavePin_WithValidFourDigitPin_Succeeds() {
        // Arrange
        let validPin = "1234"

        // Act & Assert
        XCTAssertNoThrow(try sut.savePin(pin: validPin), "Saving a valid 4-digit PIN should not throw")
    }

    func testSavePin_WithInvalidLength_ThrowsError() {
        // Arrange
        let invalidPins = ["123", "12345", "", "12"]

        for invalidPin in invalidPins {
            // Act & Assert
            XCTAssertThrowsError(try sut.savePin(pin: invalidPin)) { error in
                XCTAssertEqual(error as? PINServiceError, PINServiceError.invalidPinLength,
                             "savePin should throw invalidPinLength error for PIN: \(invalidPin)")
            }
        }
    }

    func testSavePin_WithNonNumericCharacters_ThrowsError() {
        // Arrange
        let nonNumericPins = ["abcd", "12a4", "12-4", "1 34"]

        for nonNumericPin in nonNumericPins {
            // Act & Assert
            XCTAssertThrowsError(try sut.savePin(pin: nonNumericPin)) { error in
                XCTAssertEqual(error as? PINServiceError, PINServiceError.invalidPinFormat,
                             "savePin should throw invalidPinFormat error for PIN: \(nonNumericPin)")
            }
        }
    }

    func testSavePin_OverwriteExistingPin_Succeeds() {
        // Arrange
        let firstPin = "1234"
        let secondPin = "5678"
        try? sut.savePin(pin: firstPin)

        // Act
        XCTAssertNoThrow(try sut.savePin(pin: secondPin), "Overwriting existing PIN should succeed")

        // Assert
        XCTAssertTrue(sut.verifyPin(pin: secondPin), "New PIN should be verified successfully")
        XCTAssertFalse(sut.verifyPin(pin: firstPin), "Old PIN should no longer be valid")
    }

    // MARK: - verifyPin Tests

    func testVerifyPin_WithCorrectPin_ReturnsTrue() {
        // Arrange
        let pin = "1234"
        try? sut.savePin(pin: pin)

        // Act
        let result = sut.verifyPin(pin: pin)

        // Assert
        XCTAssertTrue(result, "verifyPin should return true for correct PIN")
    }

    func testVerifyPin_WithIncorrectPin_ReturnsFalse() {
        // Arrange
        let correctPin = "1234"
        let incorrectPin = "5678"
        try? sut.savePin(pin: correctPin)

        // Act
        let result = sut.verifyPin(pin: incorrectPin)

        // Assert
        XCTAssertFalse(result, "verifyPin should return false for incorrect PIN")
    }

    func testVerifyPin_WhenNoPinSet_ReturnsFalse() {
        // Arrange: No PIN saved

        // Act
        let result = sut.verifyPin(pin: "1234")

        // Assert
        XCTAssertFalse(result, "verifyPin should return false when no PIN is set")
    }

    func testVerifyPin_CaseSensitivity_NumericPinsAreNotCaseSensitive() {
        // Arrange
        let pin = "1234"
        try? sut.savePin(pin: pin)

        // Act & Assert
        XCTAssertTrue(sut.verifyPin(pin: "1234"), "Numeric PIN should verify correctly")
    }

    // MARK: - resetPin Tests

    func testResetPin_RemovesSavedPin() {
        // Arrange
        let pin = "1234"
        try? sut.savePin(pin: pin)
        XCTAssertTrue(sut.isPinSet(), "Precondition: PIN should be set")

        // Act
        sut.resetPin()

        // Assert
        XCTAssertFalse(sut.isPinSet(), "isPinSet should return false after reset")
        XCTAssertFalse(sut.verifyPin(pin: pin), "Previous PIN should not verify after reset")
    }

    func testResetPin_WhenNoPinSet_DoesNotCrash() {
        // Arrange: No PIN set

        // Act & Assert
        XCTAssertNoThrow(sut.resetPin(), "resetPin should not crash when no PIN is set")
    }

    // MARK: - Keychain Persistence Tests

    func testPinPersistence_AcrossServiceInstances() {
        // Arrange
        let pin = "1234"
        try? sut.savePin(pin: pin)

        // Act: Create new instance
        let newService = PINService()

        // Assert: PIN should persist across instances
        XCTAssertTrue(newService.isPinSet(), "PIN should persist to Keychain")
        XCTAssertTrue(newService.verifyPin(pin: pin), "Saved PIN should be retrievable in new instance")

        // Cleanup
        newService.resetPin()
    }

    // MARK: - Security Tests

    func testSavePin_DoesNotStoreInPlainText() {
        // This is more of a contract test - we verify the implementation uses Keychain
        // In actual implementation, PINService should use Keychain, not UserDefaults or plain storage
        // This test verifies the PIN isn't stored in UserDefaults

        // Arrange
        let pin = "1234"
        try? sut.savePin(pin: pin)

        // Act: Check UserDefaults
        let userDefaults = UserDefaults.standard
        let plainTextPin = userDefaults.string(forKey: "parentPin")

        // Assert
        XCTAssertNil(plainTextPin, "PIN should not be stored in UserDefaults")
        XCTAssertNotEqual(plainTextPin, pin, "PIN should not be stored in plain text")
    }
}
