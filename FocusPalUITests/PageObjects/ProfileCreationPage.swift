//
//  ProfileCreationPage.swift
//  FocusPalUITests
//
//  Page Object for Child Profile Creation screen
//

import XCTest

class ProfileCreationPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var screenTitle: XCUIElement {
        app.staticTexts["Add Child Profile"]
    }

    var nameTextField: XCUIElement {
        app.textFields["Child Name"]
    }

    var ageLabel: XCUIElement {
        app.staticTexts["Age"]
    }

    var ageStepper: XCUIElement {
        app.steppers["AgeStepper"]
    }

    var ageValueLabel: XCUIElement {
        app.staticTexts.matching(identifier: "AgeValue").firstMatch
    }

    func ageButton(_ age: Int) -> XCUIElement {
        app.buttons["Age: \(age)"]
    }

    var avatarCollectionView: XCUIElement {
        app.collectionViews["AvatarCollection"]
    }

    func avatarButton(_ avatarId: String) -> XCUIElement {
        app.buttons[avatarId]
    }

    var themeColorPicker: XCUIElement {
        app.otherElements["ThemeColorPicker"]
    }

    func themeColorButton(_ color: String) -> XCUIElement {
        app.buttons["Theme\(color.capitalized)"]
    }

    var saveButton: XCUIElement {
        app.buttons["Save"]
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    var nameValidationError: XCUIElement {
        app.staticTexts["Please enter a name"]
    }

    var duplicateNameError: XCUIElement {
        app.staticTexts["A profile with this name already exists"]
    }

    var maxProfilesError: XCUIElement {
        app.staticTexts["Maximum of 8 profiles reached"]
    }

    // MARK: - Actions

    func enterName(_ name: String) {
        nameTextField.tap()
        nameTextField.typeText(name)
    }

    func clearName() {
        nameTextField.tap()
        nameTextField.press(forDuration: 1.0)
        if app.menuItems["Select All"].exists {
            app.menuItems["Select All"].tap()
            app.keys["delete"].tap()
        }
    }

    func selectAge(_ age: Int) {
        // Scroll to find the age if needed
        let ageBtn = ageButton(age)
        if !ageBtn.exists {
            // Use stepper to adjust age
            let currentAge = Int(ageValueLabel.label) ?? 8
            let difference = age - currentAge

            if difference > 0 {
                for _ in 0..<difference {
                    ageStepper.buttons["Increment"].tap()
                }
            } else if difference < 0 {
                for _ in 0..<abs(difference) {
                    ageStepper.buttons["Decrement"].tap()
                }
            }
        } else {
            ageBtn.tap()
        }
    }

    func selectAvatar(_ avatarId: String) {
        let avatar = avatarButton(avatarId)
        if !avatar.isHittable {
            // Scroll to find avatar
            avatarCollectionView.swipeUp()
        }
        avatar.tap()
    }

    func selectThemeColor(_ color: String) {
        themeColorButton(color).tap()
    }

    func tapSave() {
        saveButton.tap()
    }

    func tapCancel() {
        cancelButton.tap()
    }

    // MARK: - Verification

    func verifyScreenDisplayed() {
        XCTAssertTrue(screenTitle.waitForExistence(timeout: 2), "Profile creation screen should be visible")
        XCTAssertTrue(nameTextField.exists, "Name text field should be visible")
        XCTAssertTrue(saveButton.exists, "Save button should be visible")
    }

    func verifyNameValidationError() {
        XCTAssertTrue(nameValidationError.waitForExistence(timeout: 2), "Name validation error should be displayed")
    }

    func verifyDuplicateNameError() {
        XCTAssertTrue(duplicateNameError.waitForExistence(timeout: 2), "Duplicate name error should be displayed")
    }

    func verifyMaxProfilesError() {
        XCTAssertTrue(maxProfilesError.waitForExistence(timeout: 2), "Max profiles error should be displayed")
    }

    func verifySaveButtonEnabled() {
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")
    }

    func verifySaveButtonDisabled() {
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled")
    }

    // MARK: - Complete Flow

    func createProfile(name: String, age: Int, avatar: String = "avatar_default", theme: String = "blue") {
        verifyScreenDisplayed()
        enterName(name)
        selectAge(age)
        selectAvatar(avatar)
        selectThemeColor(theme)
        tapSave()
    }
}
