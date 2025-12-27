//
//  PINChangeViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for PINChangeViewModel - manages PIN change flow
@MainActor
final class PINChangeViewModelTests: XCTestCase {

    var sut: PINChangeViewModel!
    var mockPinService: SharedMockPINService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPinService = SharedMockPINService()
        mockPinService.isPinSetValue = true
        try? mockPinService.savePin(pin: "1234")
        mockPinService.verifyPinReturnValue = true
        sut = PINChangeViewModel(pinService: mockPinService)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockPinService = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_SetsCorrectInitialState() {
        XCTAssertEqual(sut.step, .verifyOld, "Initial step should be verifyOld")
        XCTAssertEqual(sut.oldPin, "", "Old PIN should be empty")
        XCTAssertEqual(sut.newPin, "", "New PIN should be empty")
        XCTAssertEqual(sut.confirmedPin, "", "Confirmed PIN should be empty")
        XCTAssertNil(sut.errorMessage, "Error message should be nil")
        XCTAssertFalse(sut.isComplete, "Should not be complete")
    }

    // MARK: - Step Flow Tests

    func testVerifyOldPin_WithCorrectPin_MovesToEnterNew() async {
        // Arrange
        mockPinService.verifyPinReturnValue = true

        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.step, .enterNew, "Should move to enterNew step")
        XCTAssertNil(sut.errorMessage, "Should have no error")
    }

    func testVerifyOldPin_WithIncorrectPin_ShowsError() async {
        // Arrange
        mockPinService.verifyPinReturnValue = false

        // Act
        sut.addDigit(5)
        sut.addDigit(6)
        sut.addDigit(7)
        sut.addDigit(8)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.step, .verifyOld, "Should stay in verifyOld step")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertEqual(sut.oldPin, "", "Should clear old PIN")
        XCTAssertTrue(sut.shouldShake, "Should trigger shake")
    }

    func testEnterNew_WithFourDigits_MovesToConfirm() {
        // Arrange
        sut.step = .enterNew

        // Act
        sut.addDigit(5)
        sut.addDigit(6)
        sut.addDigit(7)
        sut.addDigit(8)

        // Assert
        XCTAssertEqual(sut.step, .confirmNew, "Should move to confirmNew step")
    }

    func testConfirmNew_WithMatchingPin_SavesSuccessfully() async {
        // Arrange
        mockPinService.verifyPinReturnValue = true
        sut.step = .enterNew
        sut.oldPin = "1234"
        sut.newPin = "5678"
        sut.step = .confirmNew

        // Act
        sut.addDigit(5)
        sut.addDigit(6)
        sut.addDigit(7)
        sut.addDigit(8)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertTrue(mockPinService.savePinCalled, "Should save PIN")
        XCTAssertEqual(mockPinService.savedPin, "5678", "Should save new PIN")
        XCTAssertTrue(sut.isComplete, "Should be complete")
    }

    func testConfirmNew_WithNonMatchingPin_ShowsError() async {
        // Arrange
        sut.step = .confirmNew
        sut.newPin = "5678"

        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertFalse(sut.isComplete, "Should not be complete")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertEqual(sut.confirmedPin, "", "Should clear confirmed PIN")
    }

    func testConfirmNew_SameAsOldPin_ShowsError() async {
        // Arrange
        sut.step = .confirmNew
        sut.oldPin = "1234"
        sut.newPin = "1234"

        // Act
        sut.addDigit(1)
        sut.addDigit(2)
        sut.addDigit(3)
        sut.addDigit(4)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertFalse(sut.isComplete, "Should not be complete")
        XCTAssertNotNil(sut.errorMessage, "Should have error about same PIN")
        XCTAssertTrue(sut.errorMessage?.contains("different") ?? false, "Error should mention PIN must be different")
    }

    // MARK: - Navigation Tests

    func testGoBack_FromEnterNew_ReturnsToVerifyOld() {
        // Arrange
        sut.step = .enterNew
        sut.newPin = "56"

        // Act
        sut.goBack()

        // Assert
        XCTAssertEqual(sut.step, .verifyOld, "Should return to verifyOld")
        XCTAssertEqual(sut.newPin, "", "Should clear new PIN")
    }

    func testGoBack_FromConfirmNew_ReturnsToEnterNew() {
        // Arrange
        sut.step = .confirmNew
        sut.confirmedPin = "56"

        // Act
        sut.goBack()

        // Assert
        XCTAssertEqual(sut.step, .enterNew, "Should return to enterNew")
        XCTAssertEqual(sut.confirmedPin, "", "Should clear confirmed PIN")
    }

    // MARK: - Delete Tests

    func testDeleteDigit_InVerifyOldStep_RemovesFromOldPin() {
        // Arrange
        sut.addDigit(1)
        sut.addDigit(2)

        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.oldPin, "1", "Should remove from old PIN")
    }

    func testDeleteDigit_InEnterNewStep_RemovesFromNewPin() {
        // Arrange
        sut.step = .enterNew
        sut.addDigit(5)
        sut.addDigit(6)

        // Act
        sut.deleteDigit()

        // Assert
        XCTAssertEqual(sut.newPin, "5", "Should remove from new PIN")
    }

    // MARK: - Instruction Text Tests

    func testInstructionText_ChangesPerStep() {
        XCTAssertEqual(sut.instructionText, "Enter your current PIN", "Verify old step instruction")

        sut.step = .enterNew
        XCTAssertEqual(sut.instructionText, "Enter your new PIN", "Enter new step instruction")

        sut.step = .confirmNew
        XCTAssertEqual(sut.instructionText, "Confirm your new PIN", "Confirm new step instruction")
    }
}
