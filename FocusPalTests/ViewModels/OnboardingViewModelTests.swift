//
//  OnboardingViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for OnboardingViewModel - manages the onboarding flow
@MainActor
final class OnboardingViewModelTests: XCTestCase {

    var sut: OnboardingViewModel!
    var mockPINService: OnboardingMockPINService!
    var mockChildRepository: TestMockChildRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockPINService = OnboardingMockPINService()
        mockChildRepository = TestMockChildRepository()
        sut = OnboardingViewModel(
            pinService: mockPINService,
            childRepository: mockChildRepository
        )
        // Reset AppStorage property to ensure clean state for each test
        sut.hasCompletedOnboarding = false
    }

    override func tearDown() async throws {
        sut = nil
        mockPINService = nil
        mockChildRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Given: A newly initialized view model

        // Then: Initial state should be correct
        XCTAssertEqual(sut.currentStep, .welcome)
        XCTAssertEqual(sut.childName, "")
        XCTAssertEqual(sut.childAge, 8)
        XCTAssertEqual(sut.selectedAvatar, "person.circle.fill")
        XCTAssertEqual(sut.selectedTheme, "blue")
        XCTAssertFalse(sut.hasCompletedOnboarding)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Navigation Tests

    func testNextStep_FromWelcome_MovesToCreatePIN() {
        // Given: View model on welcome step
        XCTAssertEqual(sut.currentStep, .welcome)

        // When: Moving to next step
        sut.nextStep()

        // Then: Should move to createPIN step
        XCTAssertEqual(sut.currentStep, .createPIN)
    }

    func testNextStep_FromCreatePIN_MovesToCreateProfile() {
        // Given: View model on createPIN step
        sut.currentStep = .createPIN

        // When: Moving to next step
        sut.nextStep()

        // Then: Should move to createProfile step
        XCTAssertEqual(sut.currentStep, .createProfile)
    }

    func testNextStep_FromCreateProfile_MovesToPermissions() {
        // Given: View model on createProfile step
        sut.currentStep = .createProfile

        // When: Moving to next step
        sut.nextStep()

        // Then: Should move to permissions step
        XCTAssertEqual(sut.currentStep, .permissions)
    }

    func testNextStep_FromPermissions_DoesNotMove() {
        // Given: View model on last step (permissions)
        sut.currentStep = .permissions

        // When: Attempting to move to next step
        sut.nextStep()

        // Then: Should remain on permissions step
        XCTAssertEqual(sut.currentStep, .permissions)
    }

    func testPreviousStep_FromCreatePIN_MovesToWelcome() {
        // Given: View model on createPIN step
        sut.currentStep = .createPIN

        // When: Moving to previous step
        sut.previousStep()

        // Then: Should move back to welcome step
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func testPreviousStep_FromWelcome_DoesNotMove() {
        // Given: View model on first step (welcome)
        XCTAssertEqual(sut.currentStep, .welcome)

        // When: Attempting to move to previous step
        sut.previousStep()

        // Then: Should remain on welcome step
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    // MARK: - PIN Management Tests

    func testValidatePIN_WithValidPIN_ReturnsTrue() {
        // Given: A valid 4-digit PIN
        let validPin = "1234"

        // When: Validating the PIN
        let result = sut.validatePIN(validPin)

        // Then: Validation should succeed
        XCTAssertTrue(result)
        XCTAssertNil(sut.errorMessage)
    }

    func testValidatePIN_WithInvalidLength_ReturnsFalse() {
        // Given: PINs with invalid lengths
        let invalidPins = ["123", "12345", "", "12"]

        for pin in invalidPins {
            // When: Validating invalid PIN
            let result = sut.validatePIN(pin)

            // Then: Validation should fail
            XCTAssertFalse(result, "PIN '\(pin)' should be invalid")
            XCTAssertNotNil(sut.errorMessage)
        }
    }

    func testValidatePIN_WithNonNumeric_ReturnsFalse() {
        // Given: PINs with non-numeric characters
        let invalidPins = ["abcd", "12a4", "12-4", "1 34"]

        for pin in invalidPins {
            // When: Validating invalid PIN
            let result = sut.validatePIN(pin)

            // Then: Validation should fail
            XCTAssertFalse(result, "PIN '\(pin)' should be invalid")
            XCTAssertNotNil(sut.errorMessage)
        }
    }

    func testSavePIN_WithValidPIN_SavesSuccessfully() async {
        // Given: A valid PIN
        let pin = "1234"

        // When: Saving the PIN
        let result = await sut.savePIN(pin)

        // Then: Save should succeed
        XCTAssertTrue(result)
        XCTAssertEqual(mockPINService.savedPin, pin)
        XCTAssertEqual(mockPINService.savePinCallCount, 1)
        XCTAssertNil(sut.errorMessage)
    }

    func testSavePIN_WithInvalidPIN_FailsValidation() async {
        // Given: An invalid PIN
        let invalidPin = "123"

        // When: Attempting to save invalid PIN
        let result = await sut.savePIN(invalidPin)

        // Then: Save should fail
        XCTAssertFalse(result)
        XCTAssertEqual(mockPINService.savePinCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSavePIN_WhenServiceThrows_HandlesError() async {
        // Given: PIN service that throws an error
        mockPINService.shouldThrowError = true
        let pin = "1234"

        // When: Attempting to save PIN
        let result = await sut.savePIN(pin)

        // Then: Error should be handled
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testConfirmPIN_WithMatchingPINs_ReturnsTrue() {
        // Given: Matching PINs
        let pin = "1234"
        let confirmPin = "1234"

        // When: Confirming PIN
        let result = sut.confirmPIN(pin, confirmedPIN: confirmPin)

        // Then: Confirmation should succeed
        XCTAssertTrue(result)
        XCTAssertNil(sut.errorMessage)
    }

    func testConfirmPIN_WithNonMatchingPINs_ReturnsFalse() {
        // Given: Non-matching PINs
        let pin = "1234"
        let confirmPin = "5678"

        // When: Confirming PIN
        let result = sut.confirmPIN(pin, confirmedPIN: confirmPin)

        // Then: Confirmation should fail
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("match") ?? false)
    }

    // MARK: - Profile Validation Tests

    func testValidateProfile_WithValidData_ReturnsTrue() {
        // Given: Valid profile data
        sut.childName = "Emma"
        sut.childAge = 8
        sut.selectedAvatar = "person.circle.fill"

        // When: Validating profile
        let result = sut.validateProfile()

        // Then: Validation should succeed
        XCTAssertTrue(result)
        XCTAssertNil(sut.errorMessage)
    }

    func testValidateProfile_WithEmptyName_ReturnsFalse() {
        // Given: Empty child name
        sut.childName = ""
        sut.childAge = 8

        // When: Validating profile
        let result = sut.validateProfile()

        // Then: Validation should fail
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("name") ?? false)
    }

    func testValidateProfile_WithWhitespaceName_ReturnsFalse() {
        // Given: Whitespace-only name
        sut.childName = "   "
        sut.childAge = 8

        // When: Validating profile
        let result = sut.validateProfile()

        // Then: Validation should fail
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testValidateProfile_WithInvalidAge_ReturnsFalse() {
        // Given: Invalid age (below minimum)
        sut.childName = "Emma"
        sut.childAge = 2

        // When: Validating profile
        let result = sut.validateProfile()

        // Then: Validation should fail
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.lowercased().contains("age") ?? false)
    }

    func testValidateProfile_WithAgeTooHigh_ReturnsFalse() {
        // Given: Invalid age (above maximum)
        sut.childName = "Emma"
        sut.childAge = 18

        // When: Validating profile
        let result = sut.validateProfile()

        // Then: Validation should fail
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Save Profile Tests

    func testSaveChildProfile_WithValidData_SavesSuccessfully() async {
        // Given: Valid profile data
        sut.childName = "Emma"
        sut.childAge = 10
        sut.selectedAvatar = "face.smiling.fill"
        sut.selectedTheme = "purple"

        // When: Saving profile
        let result = await sut.saveChildProfile()

        // Then: Profile should be saved
        XCTAssertTrue(result)
        XCTAssertEqual(mockChildRepository.createCallCount, 1)

        // Verify saved child has correct properties
        let savedChild = mockChildRepository.createdChild
        XCTAssertEqual(savedChild?.name, "Emma")
        XCTAssertEqual(savedChild?.age, 10)
        XCTAssertEqual(savedChild?.avatarId, "face.smiling.fill")
        XCTAssertEqual(savedChild?.themeColor, "purple")
        XCTAssertTrue(savedChild?.isActive ?? false)

        XCTAssertNil(sut.errorMessage)
    }

    func testSaveChildProfile_WithInvalidData_FailsValidation() async {
        // Given: Invalid profile data
        sut.childName = ""
        sut.childAge = 10

        // When: Attempting to save profile
        let result = await sut.saveChildProfile()

        // Then: Save should fail
        XCTAssertFalse(result)
        XCTAssertEqual(mockChildRepository.createCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSaveChildProfile_WhenRepositoryThrows_HandlesError() async {
        // Given: Valid data but repository that throws error
        sut.childName = "Emma"
        sut.childAge = 10
        mockChildRepository.shouldThrowError = true

        // When: Attempting to save profile
        let result = await sut.saveChildProfile()

        // Then: Error should be handled
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Complete Onboarding Tests

    func testCompleteOnboarding_SetsCompletionFlag() async {
        // Given: All required data is saved
        sut.childName = "Emma"
        sut.childAge = 8

        // When: Completing onboarding
        await sut.completeOnboarding()

        // Then: Completion flag should be set
        XCTAssertTrue(sut.hasCompletedOnboarding)
    }

    func testCompleteOnboarding_SavesProfile() async {
        // Given: Valid profile data
        sut.childName = "Emma"
        sut.childAge = 10

        // When: Completing onboarding
        await sut.completeOnboarding()

        // Then: Profile should be saved
        XCTAssertEqual(mockChildRepository.createCallCount, 1)
    }

    // MARK: - Integration Tests

    func testOnboardingFlow_CompleteHappyPath() async {
        // Given: Starting at welcome screen
        XCTAssertEqual(sut.currentStep, .welcome)

        // When: Moving through the flow
        // Step 1: Welcome -> Create PIN
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .createPIN)

        // Step 2: Save PIN
        let pinSaved = await sut.savePIN("1234")
        XCTAssertTrue(pinSaved)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .createProfile)

        // Step 3: Fill and save profile
        sut.childName = "Emma"
        sut.childAge = 10
        sut.selectedAvatar = "star.circle.fill"
        sut.selectedTheme = "pink"

        let profileSaved = await sut.saveChildProfile()
        XCTAssertTrue(profileSaved)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, .permissions)

        // Step 4: Complete onboarding
        await sut.completeOnboarding()

        // Then: Verify complete state
        XCTAssertTrue(sut.hasCompletedOnboarding)
        XCTAssertEqual(mockPINService.savedPin, "1234")
        XCTAssertEqual(mockChildRepository.createdChild?.name, "Emma")
        XCTAssertEqual(mockChildRepository.createdChild?.age, 10)
        XCTAssertNil(sut.errorMessage)
    }

    func testOnboardingFlow_BackNavigation() {
        // Given: View model at permissions step
        sut.currentStep = .permissions

        // When: Navigating back through steps
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .createProfile)

        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .createPIN)

        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .welcome)

        // Then: Should not go before welcome
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    // MARK: - Error Handling Tests

    func testClearError_RemovesErrorMessage() {
        // Given: View model with error
        sut.errorMessage = "Test error"

        // When: Clearing error
        sut.clearError()

        // Then: Error should be cleared
        XCTAssertNil(sut.errorMessage)
    }

    func testMultipleOperations_ProperlyHandleErrors() async {
        // Given: First operation fails
        mockPINService.shouldThrowError = true

        // When: First save fails
        let firstResult = await sut.savePIN("1234")
        XCTAssertFalse(firstResult)
        XCTAssertNotNil(sut.errorMessage)

        // When: Error is cleared and retry succeeds
        sut.clearError()
        mockPINService.shouldThrowError = false

        let secondResult = await sut.savePIN("1234")

        // Then: Second attempt should succeed
        XCTAssertTrue(secondResult)
        XCTAssertNil(sut.errorMessage)
    }
}

// MARK: - Mock Services

class OnboardingMockPINService: PINServiceProtocol {
    var savedPin: String?
    var savePinCallCount = 0
    var shouldThrowError = false
    private var isPinSetValue = false

    func isPinSet() -> Bool {
        return isPinSetValue
    }

    func savePin(pin: String) throws {
        savePinCallCount += 1

        if shouldThrowError {
            throw PINServiceError.keychainError(status: errSecIO)
        }

        // Perform same validation as real service
        guard pin.count == 4 else {
            throw PINServiceError.invalidPinLength
        }

        guard pin.allSatisfy({ $0.isNumber }) else {
            throw PINServiceError.invalidPinFormat
        }

        savedPin = pin
        isPinSetValue = true
    }

    func verifyPin(pin: String) -> Bool {
        return savedPin == pin
    }

    func resetPin() {
        savedPin = nil
        isPinSetValue = false
    }
}

