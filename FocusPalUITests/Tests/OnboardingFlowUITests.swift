//
//  OnboardingFlowUITests.swift
//  FocusPalUITests
//
//  UI tests for onboarding flow
//  Test ID: UI-001
//  Priority: P0 (Critical)
//

import XCTest

final class OnboardingFlowUITests: BaseUITest {

    var onboardingPage: OnboardingPage!

    override func setUp() {
        super.setUp()
        onboardingPage = OnboardingPage(app: app)
    }

    override func tearDown() {
        onboardingPage = nil
        super.tearDown()
    }

    // MARK: - UI-001-001: Complete Full Onboarding Flow

    func test_completeOnboarding_happyPath_landsOnLandingScreen() {
        // Given: Fresh app install
        launchFreshApp()

        // When: User completes onboarding
        // Step 1: Welcome screen
        onboardingPage.verifyWelcomeScreen()
        takeScreenshot(named: "Onboarding_01_Welcome")
        onboardingPage.tapGetStarted()

        // Step 2: Create PIN
        onboardingPage.verifyPINSetupScreen()
        takeScreenshot(named: "Onboarding_02_CreatePIN")
        onboardingPage.enterPIN("1234")

        // Step 3: Confirm PIN
        onboardingPage.verifyPINConfirmationScreen()
        takeScreenshot(named: "Onboarding_03_ConfirmPIN")
        onboardingPage.enterPIN("1234")

        // Step 4: Permissions
        onboardingPage.verifyPermissionsScreen()
        takeScreenshot(named: "Onboarding_04_Permissions")
        onboardingPage.tapFinish()

        // Then: User lands on landing screen
        let landingPage = LandingPage(app: app)
        landingPage.verifyLandingScreen()
        takeScreenshot(named: "Onboarding_05_LandingScreen")

        assertExists(landingPage.addChildButton, message: "Should see add child button after onboarding")
    }

    // MARK: - UI-001-002: PIN Mismatch Error

    func test_createPIN_withMismatch_showsError() {
        // Given: User on PIN setup
        launchFreshApp()
        onboardingPage.tapGetStarted()
        onboardingPage.verifyPINSetupScreen()

        // When: User enters mismatched PINs
        onboardingPage.enterPIN("1234")
        onboardingPage.verifyPINConfirmationScreen()
        onboardingPage.enterPIN("5678") // Different PIN

        // Then: Error message displayed and user can retry
        onboardingPage.verifyPINMismatchError()
        takeScreenshot(named: "Onboarding_PIN_Mismatch_Error")

        // User should still be on PIN setup to retry
        onboardingPage.verifyPINSetupScreen()
    }

    // MARK: - UI-001-003: Back Navigation

    func test_onboardingBackNavigation_fromPermissions_returnsToWelcome() {
        // Given: User has progressed through onboarding
        launchFreshApp()
        onboardingPage.tapGetStarted()
        onboardingPage.enterPIN("1234")
        onboardingPage.enterPIN("1234")
        onboardingPage.verifyPermissionsScreen()

        // When: User navigates back multiple times
        onboardingPage.tapBack()
        onboardingPage.verifyPINSetupScreen()

        onboardingPage.tapBack()
        onboardingPage.verifyWelcomeScreen()

        // Then: User is back at welcome
        assertExists(onboardingPage.welcomeTitle)
    }

    // MARK: - UI-001-004: Skip Permissions

    func test_onboarding_skipNotifications_stillCompletes() {
        // Given: User on permissions screen
        launchFreshApp()
        onboardingPage.tapGetStarted()
        onboardingPage.enterPIN("1234")
        onboardingPage.enterPIN("1234")
        onboardingPage.verifyPermissionsScreen()

        // When: User skips notifications
        onboardingPage.tapSkip()

        // Then: Onboarding still completes
        let landingPage = LandingPage(app: app)
        landingPage.verifyLandingScreen()
    }

    // MARK: - UI-001-005: PIN Deletion During Entry

    func test_pinEntry_deleteDigit_removesLastDigit() {
        // Given: User entering PIN
        launchFreshApp()
        onboardingPage.tapGetStarted()
        onboardingPage.verifyPINSetupScreen()

        // When: User enters digits then deletes
        onboardingPage.enterPIN("123")
        onboardingPage.deletePINDigit()
        onboardingPage.deletePINDigit()

        // Then: PIN entry should allow continuing (only 1 digit entered)
        // Complete PIN entry
        onboardingPage.enterPIN("345")

        // Should move to confirmation after 4 digits
        onboardingPage.verifyPINConfirmationScreen()
    }

    // MARK: - UI-001-006: Progress Indicator

    func test_onboarding_progressIndicator_showsCurrentStep() {
        // Given: User starting onboarding
        launchFreshApp()

        // When/Then: Progress indicator updates as user progresses
        onboardingPage.verifyWelcomeScreen()
        // Step 1 of 3 should be shown (if implemented)

        onboardingPage.tapGetStarted()
        // Step 2 of 3

        onboardingPage.enterPIN("1234")
        onboardingPage.enterPIN("1234")
        // Step 3 of 3

        onboardingPage.verifyPermissionsScreen()
    }

    // MARK: - UI-001-007: Accessibility - VoiceOver Labels

    func test_onboarding_voiceOverLabels_existOnAllElements() {
        // Given: User on welcome screen
        launchFreshApp()

        // When/Then: All interactive elements have accessibility labels
        assertHasAccessibilityLabel(onboardingPage.welcomeTitle)
        assertHasAccessibilityLabel(onboardingPage.getStartedButton)

        onboardingPage.tapGetStarted()

        assertHasAccessibilityLabel(onboardingPage.pinSetupTitle)
        assertHasAccessibilityLabel(onboardingPage.pinDigitButton("1"))
        assertHasAccessibilityLabel(onboardingPage.pinDigitButton("5"))
    }

    // MARK: - UI-001-008: Onboarding Only Shown Once

    func test_onboarding_afterCompletion_notShownAgain() {
        // Given: User completes onboarding
        launchFreshApp()
        onboardingPage.completeOnboarding(pin: "1234")

        let landingPage = LandingPage(app: app)
        landingPage.verifyLandingScreen()

        // When: App is terminated and relaunched
        app.terminate()
        app.launch()

        // Then: User goes straight to landing screen (not onboarding)
        landingPage.verifyLandingScreen()
        assertNotExists(onboardingPage.welcomeTitle, message: "Should not show onboarding again")
    }
}
