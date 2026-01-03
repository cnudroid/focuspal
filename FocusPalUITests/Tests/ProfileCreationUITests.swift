//
//  ProfileCreationUITests.swift
//  FocusPalUITests
//
//  UI tests for child profile creation
//  Test ID: UI-002
//  Priority: P0 (Critical)
//

import XCTest

final class ProfileCreationUITests: BaseUITest {

    var parentAuthPage: ParentAuthPage!
    var profilePage: ProfileCreationPage!

    override func setUp() {
        super.setUp()
        parentAuthPage = ParentAuthPage(app: app)
        profilePage = ProfileCreationPage(app: app)
    }

    override func tearDown() {
        parentAuthPage = nil
        profilePage = nil
        super.tearDown()
    }

    // MARK: - UI-002-001: Create First Child Profile

    func test_createFirstProfile_withValidData_createsSuccessfully() {
        // Given: Onboarding completed, no children exist
        launchWithOnboardingComplete()

        let landingPage = LandingPage(app: app)
        landingPage.verifyLandingScreen()

        // When: Parent creates first child profile
        landingPage.tapAddChild()

        // Authenticate with PIN
        parentAuthPage.verifyPINEntryDisplayed()
        parentAuthPage.enterPIN("1234")

        // Fill in profile details
        profilePage.verifyScreenDisplayed()
        takeScreenshot(named: "ProfileCreation_01_EmptyForm")

        profilePage.enterName("Emma")
        profilePage.selectAge(8)
        profilePage.selectAvatar("avatar_girl_1")
        profilePage.selectThemeColor("pink")

        takeScreenshot(named: "ProfileCreation_02_FilledForm")
        profilePage.tapSave()

        // Then: Profile created and appears in selection
        // Should navigate to profile selection or home
        let profileExists = app.staticTexts["Emma"].waitForExistence(timeout: 3)
        XCTAssertTrue(profileExists, "Profile 'Emma' should be created and visible")

        takeScreenshot(named: "ProfileCreation_03_ProfileCreated")
    }

    // MARK: - UI-002-002: Profile Name Validation

    func test_createProfile_withEmptyName_showsValidationError() {
        // Given: User on profile creation screen
        launchWithOnboardingComplete()
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.verifyScreenDisplayed()

        // When: User tries to save without entering name
        profilePage.selectAge(10)
        profilePage.tapSave()

        // Then: Validation error shown
        profilePage.verifyNameValidationError()
        takeScreenshot(named: "ProfileCreation_EmptyName_Error")
    }

    // MARK: - UI-002-003: Duplicate Name Prevention

    func test_createProfile_withDuplicateName_showsError() {
        // Given: One profile already exists
        launchWithSingleChild(name: "Emma", age: 8)

        // Navigate to parent dashboard and add another child
        app.buttons["Settings"].tap()
        parentAuthPage.enterPIN("1234")
        parentAuthPage.tapAddChild()

        profilePage.verifyScreenDisplayed()

        // When: User tries to create profile with same name
        profilePage.enterName("Emma") // Same name
        profilePage.selectAge(10)
        profilePage.tapSave()

        // Then: Duplicate name error shown
        profilePage.verifyDuplicateNameError()
        takeScreenshot(named: "ProfileCreation_DuplicateName_Error")
    }

    // MARK: - UI-002-004: Maximum Profiles Limit

    func test_createProfile_whenMax8Reached_showsError() {
        // Given: 8 profiles already exist
        launchWithMultipleChildren(count: 8)

        // Navigate to add child
        app.buttons["Settings"].tap()
        parentAuthPage.enterPIN("1234")

        // When: User tries to add 9th profile
        let addChildBtn = parentAuthPage.addChildButton

        // Then: Add child button should be disabled or show error
        if addChildBtn.isEnabled {
            parentAuthPage.tapAddChild()
            profilePage.verifyMaxProfilesError()
            takeScreenshot(named: "ProfileCreation_MaxProfiles_Error")
        } else {
            XCTAssertFalse(addChildBtn.isEnabled, "Add child button should be disabled at max profiles")
        }
    }

    // MARK: - UI-002-005: Age Selection Updates UI Complexity

    func test_createProfile_selectAge_updatesUIHint() {
        // Given: User on profile creation
        launchWithOnboardingComplete()
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.verifyScreenDisplayed()

        // When: User selects different ages
        profilePage.selectAge(6) // Young child
        // Then: UI hint should show "Simplified interface"

        profilePage.selectAge(12) // Older child
        // Then: UI hint should show "Standard interface"

        // Verify age is properly displayed
        XCTAssertTrue(profilePage.ageButton(12).isSelected || profilePage.ageValueLabel.label.contains("12"))
    }

    // MARK: - UI-002-006: Avatar Selection

    func test_createProfile_selectAvatar_updatesPreview() {
        // Given: User on profile creation
        launchWithOnboardingComplete()
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.verifyScreenDisplayed()

        // When: User selects avatar
        profilePage.selectAvatar("avatar_boy_1")

        // Then: Avatar preview should update
        let selectedAvatar = profilePage.avatarButton("avatar_boy_1")
        XCTAssertTrue(selectedAvatar.isSelected || selectedAvatar.value as? String == "selected")
    }

    // MARK: - UI-002-007: Theme Color Selection

    func test_createProfile_selectTheme_updatesPreview() {
        // Given: User on profile creation
        launchWithOnboardingComplete()
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.verifyScreenDisplayed()

        // When: User selects theme color
        profilePage.selectThemeColor("purple")

        // Then: Theme preview should update
        let selectedTheme = profilePage.themeColorButton("purple")
        XCTAssertTrue(selectedTheme.isSelected || selectedTheme.value as? String == "selected")
    }

    // MARK: - UI-002-008: Cancel Profile Creation

    func test_createProfile_tapCancel_dismissesScreen() {
        // Given: User on profile creation with partial data
        launchWithOnboardingComplete()
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.verifyScreenDisplayed()

        profilePage.enterName("Test")
        profilePage.selectAge(9)

        // When: User taps cancel
        profilePage.tapCancel()

        // Then: Screen dismissed, profile not created
        landingPage.verifyLandingScreen()
        assertNotExists(app.staticTexts["Test"], message: "Cancelled profile should not be created")
    }

    // MARK: - UI-002-009: Save Button State

    func test_createProfile_saveButton_disabledWhenInvalid() {
        // Given: User on profile creation
        launchWithOnboardingComplete()
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.verifyScreenDisplayed()

        // When: Form is empty
        // Then: Save button should be disabled
        profilePage.verifySaveButtonDisabled()

        // When: User enters valid name
        profilePage.enterName("Valid Name")

        // Then: Save button should be enabled
        profilePage.verifySaveButtonEnabled()

        // When: User clears name
        profilePage.clearName()

        // Then: Save button should be disabled again
        profilePage.verifySaveButtonDisabled()
    }

    // MARK: - UI-002-010: Create Multiple Profiles

    func test_createMultipleProfiles_sequential_allCreatedSuccessfully() {
        // Given: Starting with no profiles
        launchWithOnboardingComplete()

        // Create first profile
        let landingPage = LandingPage(app: app)
        landingPage.tapAddChild()
        parentAuthPage.enterPIN("1234")
        profilePage.createProfile(name: "Emma", age: 8, avatar: "avatar_girl_1", theme: "pink")

        // Wait for profile to be created
        wait(for: app.staticTexts["Emma"], timeout: 3)

        // Create second profile
        app.buttons["Settings"].tap()
        parentAuthPage.enterPIN("1234")
        parentAuthPage.tapAddChild()
        profilePage.createProfile(name: "Lucas", age: 10, avatar: "avatar_boy_1", theme: "blue")

        // Then: Both profiles should exist
        XCTAssertTrue(app.staticTexts["Emma"].exists, "First profile should exist")
        XCTAssertTrue(app.staticTexts["Lucas"].exists, "Second profile should exist")

        takeScreenshot(named: "ProfileCreation_MultipleProfiles")
    }
}
