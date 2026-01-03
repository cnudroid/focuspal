//
//  ParentAuthPage.swift
//  FocusPalUITests
//
//  Page Object for Parent Authentication and Parent Dashboard
//

import XCTest

class ParentAuthPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - PIN Entry Elements

    var pinEntryTitle: XCUIElement {
        app.staticTexts["Enter Parent PIN"]
    }

    var pinDotsDisplay: XCUIElement {
        app.otherElements["PINDotsDisplay"]
    }

    func pinDigitButton(_ digit: String) -> XCUIElement {
        app.buttons[digit]
    }

    var pinDeleteButton: XCUIElement {
        app.buttons["Delete"]
    }

    var incorrectPINError: XCUIElement {
        app.staticTexts["Incorrect PIN. Please try again."]
    }

    var tooManyAttemptsError: XCUIElement {
        app.staticTexts["Too many incorrect attempts. Please wait 30 seconds."]
    }

    var biometricButton: XCUIElement {
        app.buttons["Use Face ID"]
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    // MARK: - Parent Dashboard Elements

    var dashboardTitle: XCUIElement {
        app.staticTexts["Parent Dashboard"]
    }

    var childProfilesSection: XCUIElement {
        app.otherElements["ChildProfiles"]
    }

    var addChildButton: XCUIElement {
        app.buttons["Add Child"]
    }

    var categoryManagementButton: XCUIElement {
        app.buttons["Category Management"]
    }

    var timeGoalsButton: XCUIElement {
        app.buttons["Time Goals"]
    }

    var reportsButton: XCUIElement {
        app.buttons["Reports"]
    }

    var settingsButton: XCUIElement {
        app.buttons["Parent Settings"]
    }

    var changePINButton: XCUIElement {
        app.buttons["Change PIN"]
    }

    var emailSettingsButton: XCUIElement {
        app.buttons["Email Settings"]
    }

    var logoutButton: XCUIElement {
        app.buttons["Close"]
    }

    // MARK: - Category Management Elements

    var categoryManagementTitle: XCUIElement {
        app.staticTexts["Category Management"]
    }

    var categoriesList: XCUIElement {
        app.tables["CategoriesList"]
    }

    func categoryCell(_ categoryName: String) -> XCUIElement {
        categoriesList.cells.containing(.staticText, identifier: categoryName).firstMatch
    }

    var addCategoryButton: XCUIElement {
        app.buttons["Add Category"]
    }

    // MARK: - Category Editor Elements

    var categoryEditorTitle: XCUIElement {
        app.staticTexts["Edit Category"]
    }

    var categoryNameField: XCUIElement {
        app.textFields["Category Name"]
    }

    var categoryColorPicker: XCUIElement {
        app.otherElements["ColorPicker"]
    }

    var categoryIconPicker: XCUIElement {
        app.otherElements["IconPicker"]
    }

    var categoryActiveToggle: XCUIElement {
        app.switches["Category Active"]
    }

    var saveCategoryButton: XCUIElement {
        app.buttons["Save"]
    }

    var deleteCategoryButton: XCUIElement {
        app.buttons["Delete Category"]
    }

    // MARK: - Time Goals Elements

    var timeGoalsTitle: XCUIElement {
        app.staticTexts["Time Goals"]
    }

    var goalsList: XCUIElement {
        app.tables["TimeGoalsList"]
    }

    func goalCell(_ categoryName: String) -> XCUIElement {
        goalsList.cells.containing(.staticText, identifier: categoryName).firstMatch
    }

    func goalSlider(_ categoryName: String) -> XCUIElement {
        app.sliders["Goal_\(categoryName)"]
    }

    var saveGoalsButton: XCUIElement {
        app.buttons["Save Goals"]
    }

    // MARK: - Actions - Authentication

    func enterPIN(_ pin: String) {
        XCTAssertEqual(pin.count, 4, "PIN must be 4 digits")

        for digit in pin {
            pinDigitButton(String(digit)).tap()
        }
    }

    func deletePINDigit() {
        pinDeleteButton.tap()
    }

    func tapUseBiometric() {
        biometricButton.tap()
    }

    func tapCancel() {
        cancelButton.tap()
    }

    // MARK: - Actions - Dashboard

    func tapAddChild() {
        addChildButton.tap()
    }

    func tapCategoryManagement() {
        categoryManagementButton.tap()
    }

    func tapTimeGoals() {
        timeGoalsButton.tap()
    }

    func tapReports() {
        reportsButton.tap()
    }

    func tapSettings() {
        settingsButton.tap()
    }

    func tapChangePIN() {
        changePINButton.tap()
    }

    func tapEmailSettings() {
        emailSettingsButton.tap()
    }

    func tapLogout() {
        logoutButton.tap()
    }

    // MARK: - Actions - Category Management

    func tapAddCategory() {
        addCategoryButton.tap()
    }

    func tapCategory(_ categoryName: String) {
        categoryCell(categoryName).tap()
    }

    func editCategoryName(_ newName: String) {
        categoryNameField.tap()
        categoryNameField.clearText()
        categoryNameField.typeText(newName)
    }

    func toggleCategoryActive() {
        categoryActiveToggle.tap()
    }

    func tapSaveCategory() {
        saveCategoryButton.tap()
    }

    func tapDeleteCategory() {
        deleteCategoryButton.tap()
    }

    // MARK: - Actions - Time Goals

    func setGoal(category: String, minutes: Int) {
        let slider = goalSlider(category)
        // Adjust slider to desired value
        slider.adjust(toNormalizedSliderPosition: CGFloat(minutes) / 180.0) // Assuming max is 180 minutes
    }

    func tapSaveGoals() {
        saveGoalsButton.tap()
    }

    // MARK: - Verification Methods

    func verifyPINEntryDisplayed() {
        XCTAssertTrue(pinEntryTitle.waitForExistence(timeout: 2), "PIN entry screen should be visible")
        XCTAssertTrue(pinDigitButton("1").exists, "PIN digit buttons should be visible")
    }

    func verifyIncorrectPINError() {
        XCTAssertTrue(incorrectPINError.waitForExistence(timeout: 2), "Incorrect PIN error should be displayed")
    }

    func verifyTooManyAttemptsError() {
        XCTAssertTrue(tooManyAttemptsError.waitForExistence(timeout: 2), "Too many attempts error should be displayed")
    }

    func verifyDashboardDisplayed() {
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 2), "Dashboard should be visible")
        XCTAssertTrue(addChildButton.exists, "Add child button should be visible")
    }

    func verifyCategoryManagementDisplayed() {
        XCTAssertTrue(categoryManagementTitle.waitForExistence(timeout: 2), "Category management should be visible")
        XCTAssertTrue(categoriesList.exists, "Categories list should be visible")
    }

    func verifyCategoryEditorDisplayed() {
        XCTAssertTrue(categoryEditorTitle.waitForExistence(timeout: 2), "Category editor should be visible")
        XCTAssertTrue(categoryNameField.exists, "Category name field should be visible")
    }

    func verifyTimeGoalsDisplayed() {
        XCTAssertTrue(timeGoalsTitle.waitForExistence(timeout: 2), "Time goals should be visible")
        XCTAssertTrue(goalsList.exists, "Goals list should be visible")
    }

    func verifyCategoryExists(_ categoryName: String) {
        XCTAssertTrue(categoryCell(categoryName).exists, "Category \(categoryName) should exist in list")
    }

    func verifyCategoryNotExists(_ categoryName: String) {
        XCTAssertFalse(categoryCell(categoryName).exists, "Category \(categoryName) should not exist in list")
    }

    // MARK: - Complete Flows

    func authenticateWithPIN(_ pin: String) {
        verifyPINEntryDisplayed()
        enterPIN(pin)
        verifyDashboardDisplayed()
    }

    func createCategory(name: String, activate: Bool = true) {
        tapAddCategory()
        verifyCategoryEditorDisplayed()
        editCategoryName(name)

        if !activate {
            toggleCategoryActive()
        }

        tapSaveCategory()
        verifyCategoryManagementDisplayed()
    }
}

// MARK: - XCUIElement Extension for Text Clearing

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        self.tap()

        if !stringValue.isEmpty {
            self.press(forDuration: 1.0)

            let selectAll = XCUIApplication().menuItems["Select All"]
            if selectAll.waitForExistence(timeout: 0.5) {
                selectAll.tap()
            }

            let deleteKey = XCUIApplication().keys["delete"]
            if deleteKey.exists {
                deleteKey.tap()
            }
        }
    }
}
