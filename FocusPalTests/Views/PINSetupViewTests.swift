//
//  PINSetupViewTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import SwiftUI
@testable import FocusPal

/// Tests for PINSetupViewModel - manages first-time PIN creation
@MainActor
final class PINSetupViewModelTests: XCTestCase {

    var sut: PINSetupViewModel!
    var mockPinService: MockPINService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPinService = MockPINService()
        sut = PINSetupViewModel(pinService: mockPinService)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockPinService = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_SetsCorrectInitialState() {
        // Assert
        XCTAssertEqual(sut.step, .enterPin, "Initial step should be enterPin")
        XCTAssertEqual(sut.enteredPin, "", "Initial entered PIN should be empty")
        XCTAssertEqual(sut.confirmedPin, "", "Initial confirmed PIN should be empty")
        XCTAssertNil(sut.errorMessage, "Initial error message should be nil")
        XCTAssertFalse(sut.isComplete, "Should not be complete initially")
    }

    // MARK: - addDigit Tests

    func testAddDigit_InEnterPinStep_AddsToEnteredPin() {
        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)

        // Assert
        XCTAssertEqual(sut.enteredPin, "123", "Should add digits to entered PIN")
    }

    func testAddDigit_InConfirmPinStep_AddsToConfirmedPin() {
        // Arrange
        sut.step = .confirmPin
        sut.enteredPin = "1234"

        // Act
        sut.addDigit(1)
        sut.addDigit(2)

        // Assert
        XCTAssertEqual(sut.confirmedPin, "12", "Should add digits to confirmed PIN")
    }

    func testAddDigit_WhenFourDigitsInEnterStep_MovesToConfirmStep() {
        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        // Assert
        XCTAssertEqual(sut.step, .confirmPin, "Should move to confirm step after 4 digits")
    }

    func testAddDigit_WhenFourDigitsInConfirmStep_VerifiesPins() async {
        // Arrange
        sut.enteredPin = "1234"
        sut.step = .confirmPin

        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertTrue(mockPinService.savePinCalled, "Should save PIN when confirmed")
        XCTAssertTrue(sut.isComplete, "Should be complete after successful save")
    }

    func testAddDigit_DoesNotExceedFourDigits() {
        // Act
        for i in 1...6 {
            sut.addDigit(i)
        }

        // Assert
        XCTAssertEqual(sut.enteredPin.count, 4, "Should not exceed 4 digits")
    }

    // MARK: - deleteDigit Tests

    func testDeleteDigit_InEnterPinStep_RemovesFromEnteredPin() {
        // Arrange
        sut.addDigit(1)
        sut.addDigit(2)

        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.enteredPin, "1", "Should remove last digit from entered PIN")
    }

    func testDeleteDigit_InConfirmPinStep_RemovesFromConfirmedPin() {
        // Arrange
        sut.step = .confirmPin
        sut.enteredPin = "1234"
        sut.addDigit(1)
        sut.addDigit(2)

        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.confirmedPin, "1", "Should remove last digit from confirmed PIN")
    }

    func testDeleteDigit_WhenEmpty_DoesNothing() {
        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.enteredPin, "", "Should remain empty")
    }

    // MARK: - goBack Tests

    func testGoBack_FromConfirmStep_ReturnsToEnterStep() {
        // Arrange
        sut.enteredPin = "1234"
        sut.step = .confirmPin
        sut.confirmedPin = "12"

        // Act
        sut.goBack()

        // Assert
        XCTAssertEqual(sut.step, .enterPin, "Should return to enter PIN step")
        XCTAssertEqual(sut.confirmedPin, "", "Should clear confirmed PIN")
        XCTAssertNil(sut.errorMessage, "Should clear error message")
    }

    // MARK: - PIN Confirmation Tests

    func testVerifyAndSavePin_WithMatchingPins_SavesSuccessfully() async {
        // Arrange
        sut.enteredPin = "1234"
        sut.confirmedPin = "1234"

        // Act
        await sut.verifyAndSavePin()

        // Assert
        XCTAssertTrue(mockPinService.savePinCalled, "Should call savePin")
        XCTAssertEqual(mockPinService.savedPin, "1234", "Should save the correct PIN")
        XCTAssertTrue(sut.isComplete, "Should be complete after successful save")
        XCTAssertNil(sut.errorMessage, "Should have no error message")
    }

    func testVerifyAndSavePin_WithNonMatchingPins_ShowsError() async {
        // Arrange
        sut.enteredPin = "1234"
        sut.confirmedPin = "5678"

        // Act
        await sut.verifyAndSavePin()

        // Assert
        XCTAssertFalse(mockPinService.savePinCalled, "Should not call savePin")
        XCTAssertFalse(sut.isComplete, "Should not be complete")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertEqual(sut.confirmedPin, "", "Should clear confirmed PIN")
    }

    func testVerifyAndSavePin_WithServiceError_ShowsError() async {
        // Arrange
        sut.enteredPin = "1234"
        sut.confirmedPin = "1234"
        mockPinService.shouldThrowError = true

        // Act
        await sut.verifyAndSavePin()

        // Assert
        XCTAssertFalse(sut.isComplete, "Should not be complete on error")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
    }

    // MARK: - Current PIN Display Tests

    func testCurrentPin_InEnterStep_ReturnsEnteredPin() {
        // Arrange
        sut.addDigit(1)
        sut.addDigit(2)

        // Act
        let current = sut.currentPin

        // Assert
        XCTAssertEqual(current, "12", "Should return entered PIN in enter step")
    }

    func testCurrentPin_InConfirmStep_ReturnsConfirmedPin() {
        // Arrange
        sut.enteredPin = "1234"
        sut.step = .confirmPin
        sut.addDigit(1)

        // Act
        let current = sut.currentPin

        // Assert
        XCTAssertEqual(current, "1", "Should return confirmed PIN in confirm step")
    }
}

// MARK: - Enhanced Mock PINService

extension MockPINService {
    var shouldThrowError = false

    func savePin(pin: String, throwError: Bool) throws {
        if shouldThrowError {
            throw PINServiceError.keychainError(status: -1)
        }
        try savePin(pin: pin)
    }
}
