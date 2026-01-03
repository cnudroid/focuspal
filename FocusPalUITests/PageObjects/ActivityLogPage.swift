//
//  ActivityLogPage.swift
//  FocusPalUITests
//
//  Page Object for Activity Log and Quick Log screens
//

import XCTest

class ActivityLogPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Quick Log Elements

    var quickLogTitle: XCUIElement {
        app.staticTexts["Quick Log"]
    }

    var categoryGrid: XCUIElement {
        app.collectionViews["CategoryGrid"]
    }

    func quickLogCategoryButton(_ categoryName: String) -> XCUIElement {
        app.buttons["QuickLog_\(categoryName)"]
    }

    var currentActivityIndicator: XCUIElement {
        app.otherElements["CurrentActivityIndicator"]
    }

    var currentActivityLabel: XCUIElement {
        app.staticTexts["CurrentActivity"]
    }

    var activityDurationLabel: XCUIElement {
        app.staticTexts["ActivityDuration"]
    }

    // MARK: - Activity History Elements

    var activityHistoryTitle: XCUIElement {
        app.staticTexts["Today's Activities"]
    }

    var activityList: XCUIElement {
        app.tables["ActivityList"]
    }

    func activityCell(_ index: Int) -> XCUIElement {
        activityList.cells.element(boundBy: index)
    }

    func activityCellWithCategory(_ categoryName: String) -> XCUIElement {
        activityList.cells.containing(.staticText, identifier: categoryName).firstMatch
    }

    var emptyStateView: XCUIElement {
        app.otherElements["EmptyActivityList"]
    }

    var emptyStateMessage: XCUIElement {
        app.staticTexts["No activities logged yet"]
    }

    // MARK: - Activity Detail Elements

    var activityDetailView: XCUIElement {
        app.otherElements["ActivityDetailView"]
    }

    var activityCategoryLabel: XCUIElement {
        app.staticTexts["ActivityCategory"]
    }

    var activityStartTimeLabel: XCUIElement {
        app.staticTexts["ActivityStartTime"]
    }

    var activityEndTimeLabel: XCUIElement {
        app.staticTexts["ActivityEndTime"]
    }

    var activityDurationDetailLabel: XCUIElement {
        app.staticTexts["ActivityDurationDetail"]
    }

    var activityNotesTextView: XCUIElement {
        app.textViews["ActivityNotes"]
    }

    var activityMoodPicker: XCUIElement {
        app.otherElements["MoodPicker"]
    }

    func moodButton(_ mood: String) -> XCUIElement {
        app.buttons["Mood_\(mood)"]
    }

    var completionToggle: XCUIElement {
        app.switches["ActivityCompletion"]
    }

    var editButton: XCUIElement {
        app.buttons["Edit"]
    }

    var deleteButton: XCUIElement {
        app.buttons["Delete"]
    }

    var saveButton: XCUIElement {
        app.buttons["Save"]
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    // MARK: - Manual Entry Elements

    var addActivityButton: XCUIElement {
        app.buttons["Add Activity"]
    }

    var manualEntryView: XCUIElement {
        app.otherElements["ManualEntryView"]
    }

    var manualEntryTitle: XCUIElement {
        app.staticTexts["Add Activity"]
    }

    var categoryPicker: XCUIElement {
        app.buttons["CategoryPicker"]
    }

    func categoryPickerOption(_ categoryName: String) -> XCUIElement {
        app.buttons[categoryName]
    }

    var startTimePicker: XCUIElement {
        app.datePickers["StartTime"]
    }

    var endTimePicker: XCUIElement {
        app.datePickers["EndTime"]
    }

    var notesTextField: XCUIElement {
        app.textFields["Notes"]
    }

    var manualEntryIndicator: XCUIElement {
        app.images["ManualEntryIcon"]
    }

    // MARK: - Validation Errors

    var endTimeBeforeStartError: XCUIElement {
        app.staticTexts["End time must be after start time"]
    }

    var overlappingActivityError: XCUIElement {
        app.staticTexts["This activity overlaps with an existing activity"]
    }

    var notesTooLongError: XCUIElement {
        app.staticTexts["Notes cannot exceed 200 characters"]
    }

    // MARK: - Actions - Quick Log

    func quickLogActivity(_ categoryName: String) {
        quickLogCategoryButton(categoryName).tap()
    }

    func verifyCurrentActivity(_ categoryName: String) {
        XCTAssertTrue(currentActivityLabel.label.contains(categoryName), "Current activity should be \(categoryName)")
    }

    // MARK: - Actions - Activity History

    func tapActivityCell(_ index: Int) {
        activityCell(index).tap()
    }

    func tapActivityWithCategory(_ categoryName: String) {
        activityCellWithCategory(categoryName).tap()
    }

    func deleteActivityWithSwipe(_ index: Int) {
        let cell = activityCell(index)
        cell.swipeLeft()
        cell.buttons["Delete"].tap()
    }

    // MARK: - Actions - Activity Detail

    func tapEdit() {
        editButton.tap()
    }

    func tapDelete() {
        deleteButton.tap()
    }

    func confirmDelete() {
        app.buttons["Delete"].tap()
    }

    func editNotes(_ notes: String) {
        activityNotesTextView.tap()
        activityNotesTextView.typeText(notes)
    }

    func selectMood(_ mood: String) {
        moodButton(mood).tap()
    }

    func toggleCompletion() {
        completionToggle.tap()
    }

    func tapSave() {
        saveButton.tap()
    }

    func tapCancel() {
        cancelButton.tap()
    }

    // MARK: - Actions - Manual Entry

    func tapAddActivity() {
        addActivityButton.tap()
    }

    func selectCategory(_ categoryName: String) {
        categoryPicker.tap()
        categoryPickerOption(categoryName).tap()
    }

    func setStartTime(hour: Int, minute: Int) {
        startTimePicker.tap()
        // Adjust pickers - this is simplified, actual implementation may vary
        let hourValue = String(format: "%02d", hour)
        let minuteValue = String(format: "%02d", minute)

        startTimePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: hourValue)
        startTimePicker.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: minuteValue)
    }

    func setEndTime(hour: Int, minute: Int) {
        endTimePicker.tap()
        let hourValue = String(format: "%02d", hour)
        let minuteValue = String(format: "%02d", minute)

        endTimePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: hourValue)
        endTimePicker.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: minuteValue)
    }

    func enterNotes(_ notes: String) {
        notesTextField.tap()
        notesTextField.typeText(notes)
    }

    // MARK: - Verification Methods

    func verifyQuickLogScreenDisplayed() {
        XCTAssertTrue(quickLogTitle.waitForExistence(timeout: 2), "Quick log screen should be visible")
        XCTAssertTrue(categoryGrid.exists, "Category grid should be visible")
    }

    func verifyActivityHistoryDisplayed() {
        XCTAssertTrue(activityHistoryTitle.waitForExistence(timeout: 2), "Activity history should be visible")
    }

    func verifyActivityCount(_ expectedCount: Int) {
        let actualCount = activityList.cells.count
        XCTAssertEqual(actualCount, expectedCount, "Should have \(expectedCount) activities")
    }

    func verifyEmptyState() {
        XCTAssertTrue(emptyStateView.exists, "Empty state should be displayed")
        XCTAssertTrue(emptyStateMessage.exists, "Empty state message should be visible")
    }

    func verifyActivityDetailDisplayed() {
        XCTAssertTrue(activityDetailView.waitForExistence(timeout: 2), "Activity detail should be visible")
    }

    func verifyManualEntryScreenDisplayed() {
        XCTAssertTrue(manualEntryView.waitForExistence(timeout: 2), "Manual entry screen should be visible")
        XCTAssertTrue(manualEntryTitle.exists, "Manual entry title should be visible")
    }

    func verifyActivityLogged(_ categoryName: String) {
        XCTAssertTrue(activityCellWithCategory(categoryName).waitForExistence(timeout: 2), "Activity with category \(categoryName) should be logged")
    }

    func verifyEndTimeBeforeStartError() {
        XCTAssertTrue(endTimeBeforeStartError.waitForExistence(timeout: 2), "End time validation error should be displayed")
    }

    func verifyOverlappingActivityError() {
        XCTAssertTrue(overlappingActivityError.waitForExistence(timeout: 2), "Overlapping activity error should be displayed")
    }

    func verifyNotesTooLongError() {
        XCTAssertTrue(notesTooLongError.waitForExistence(timeout: 2), "Notes too long error should be displayed")
    }

    // MARK: - Complete Flows

    func logManualActivity(category: String, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, notes: String? = nil) {
        tapAddActivity()
        verifyManualEntryScreenDisplayed()
        selectCategory(category)
        setStartTime(hour: startHour, minute: startMinute)
        setEndTime(hour: endHour, minute: endMinute)

        if let notes = notes {
            enterNotes(notes)
        }

        tapSave()
    }

    func editActivity(index: Int, newNotes: String, newMood: String) {
        tapActivityCell(index)
        verifyActivityDetailDisplayed()
        tapEdit()
        editNotes(newNotes)
        selectMood(newMood)
        tapSave()
    }
}
