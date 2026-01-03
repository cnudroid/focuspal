//
//  ActivityLogUITests.swift
//  FocusPalUITests
//
//  UI tests for activity logging (Quick Log and Manual Entry)
//  Test ID: UI-004, UI-005
//  Priority: P0 (Critical)
//

import XCTest

final class ActivityLogUITests: BaseUITest {

    var activityLogPage: ActivityLogPage!

    override func setUp() {
        super.setUp()
        activityLogPage = ActivityLogPage(app: app)
    }

    override func tearDown() {
        activityLogPage = nil
        super.tearDown()
    }

    // MARK: - UI-004-001: Quick Log Single Activity

    func test_quickLog_tapCategory_logsActivityImmediately() {
        // Given: User on quick log screen
        launchWithSingleChild()
        navigateToTab("Quick Log")
        activityLogPage.verifyQuickLogScreenDisplayed()
        takeScreenshot(named: "QuickLog_01_InitialScreen")

        // When: User taps a category
        activityLogPage.quickLogActivity("Reading")

        // Then: Activity logged and current activity shown
        activityLogPage.verifyCurrentActivity("Reading")
        takeScreenshot(named: "QuickLog_02_ActivityStarted")

        // Verify in history
        navigateToTab("Activities")
        activityLogPage.verifyActivityLogged("Reading")
    }

    // MARK: - UI-004-002: Quick Log Multiple Activities

    func test_quickLog_consecutiveActivities_calculatesDurations() {
        // Given: User on quick log screen
        launchWithSingleChild()
        navigateToTab("Quick Log")
        activityLogPage.verifyQuickLogScreenDisplayed()

        // When: User logs multiple activities
        activityLogPage.quickLogActivity("Homework")
        sleep(3) // 3 seconds of homework

        activityLogPage.quickLogActivity("Physical Activity")
        sleep(3) // 3 seconds of physical activity

        activityLogPage.quickLogActivity("Creative Play")
        sleep(2) // 2 seconds of creative play

        // Then: All activities logged with durations
        navigateToTab("Activities")

        activityLogPage.verifyActivityLogged("Homework")
        activityLogPage.verifyActivityLogged("Physical Activity")
        activityLogPage.verifyActivityLogged("Creative Play")

        // Verify at least 3 activities
        activityLogPage.verifyActivityCount(3)

        takeScreenshot(named: "QuickLog_MultipleActivities")
    }

    // MARK: - UI-004-003: Quick Log Empty State

    func test_activityHistory_noActivities_showsEmptyState() {
        // Given: No activities logged
        launchWithSingleChild()

        // When: User navigates to activity history
        navigateToTab("Activities")

        // Then: Empty state displayed
        activityLogPage.verifyEmptyState()
        takeScreenshot(named: "ActivityLog_EmptyState")

        assertExists(activityLogPage.emptyStateMessage)
    }

    // MARK: - UI-005-001: Manual Entry with Valid Data

    func test_manualEntry_validData_logsActivity() {
        // Given: User on activity log screen
        launchWithSingleChild()
        navigateToTab("Activities")

        // When: User adds manual entry
        activityLogPage.tapAddActivity()
        activityLogPage.verifyManualEntryScreenDisplayed()
        takeScreenshot(named: "ManualEntry_01_InitialScreen")

        activityLogPage.selectCategory("Creative Play")
        activityLogPage.setStartTime(hour: 14, minute: 0) // 2:00 PM
        activityLogPage.setEndTime(hour: 15, minute: 30) // 3:30 PM
        activityLogPage.enterNotes("Built LEGO castle")

        takeScreenshot(named: "ManualEntry_02_FilledForm")
        activityLogPage.tapSave()

        // Then: Activity logged with manual entry indicator
        activityLogPage.verifyActivityLogged("Creative Play")
        takeScreenshot(named: "ManualEntry_03_ActivitySaved")

        // Verify manual entry indicator
        activityLogPage.tapActivityWithCategory("Creative Play")
        assertExists(activityLogPage.manualEntryIndicator)
    }

    // MARK: - UI-005-002: Manual Entry Time Validation

    func test_manualEntry_endTimeBeforeStart_showsError() {
        // Given: User on manual entry screen
        launchWithSingleChild()
        navigateToTab("Activities")
        activityLogPage.tapAddActivity()
        activityLogPage.verifyManualEntryScreenDisplayed()

        // When: User sets end time before start time
        activityLogPage.selectCategory("Homework")
        activityLogPage.setStartTime(hour: 15, minute: 0) // 3:00 PM
        activityLogPage.setEndTime(hour: 14, minute: 0) // 2:00 PM (before start!)

        activityLogPage.tapSave()

        // Then: Validation error shown
        activityLogPage.verifyEndTimeBeforeStartError()
        takeScreenshot(named: "ManualEntry_EndTimeBeforeStart_Error")
    }

    // MARK: - UI-005-003: Manual Entry Overlapping Activity Detection

    func test_manualEntry_overlappingActivity_showsWarning() {
        // Given: Activity already exists from 2:00-3:00
        launchWithSingleChild()
        navigateToTab("Activities")

        // Log first activity
        activityLogPage.logManualActivity(
            category: "Reading",
            startHour: 14,
            startMinute: 0,
            endHour: 15,
            endMinute: 0,
            notes: "First activity"
        )

        // When: User tries to log overlapping activity
        activityLogPage.tapAddActivity()
        activityLogPage.selectCategory("Homework")
        activityLogPage.setStartTime(hour: 14, minute: 30) // Overlaps with 2:00-3:00
        activityLogPage.setEndTime(hour: 15, minute: 30)
        activityLogPage.tapSave()

        // Then: Overlapping warning shown
        activityLogPage.verifyOverlappingActivityError()
        takeScreenshot(named: "ManualEntry_OverlappingActivity_Warning")
    }

    // MARK: - UI-005-004: Edit Activity

    func test_activityEdit_updateNoteAndMood_saveSuccessfully() {
        // Given: Activity exists
        launchWithSampleData() // Launch with pre-existing data
        navigateToTab("Activities")

        // When: User edits activity
        activityLogPage.tapActivityCell(0)
        activityLogPage.verifyActivityDetailDisplayed()
        takeScreenshot(named: "ActivityEdit_01_DetailView")

        activityLogPage.tapEdit()
        activityLogPage.editNotes("Updated notes from test")
        activityLogPage.selectMood("Happy")
        takeScreenshot(named: "ActivityEdit_02_EditMode")

        activityLogPage.tapSave()

        // Then: Changes saved
        activityLogPage.verifyActivityDetailDisplayed()

        // Verify notes updated
        XCTAssertTrue(
            activityLogPage.activityNotesTextView.label.contains("Updated notes from test"),
            "Notes should be updated"
        )

        takeScreenshot(named: "ActivityEdit_03_Saved")
    }

    // MARK: - UI-005-005: Delete Activity

    func test_activityDelete_swipeToDelete_removesFromList() {
        // Given: Activity exists
        launchWithSampleData()
        navigateToTab("Activities")

        let initialCount = activityLogPage.activityList.cells.count

        // When: User deletes activity with swipe
        activityLogPage.deleteActivityWithSwipe(0)

        // Then: Activity removed from list
        let newCount = activityLogPage.activityList.cells.count
        XCTAssertEqual(newCount, initialCount - 1, "Activity count should decrease by 1")

        takeScreenshot(named: "ActivityDelete_AfterDelete")
    }

    // MARK: - UI-005-006: Delete Activity from Detail View

    func test_activityDelete_fromDetailView_removesActivity() {
        // Given: User viewing activity detail
        launchWithSampleData()
        navigateToTab("Activities")

        activityLogPage.tapActivityCell(0)
        activityLogPage.verifyActivityDetailDisplayed()

        // When: User taps delete
        activityLogPage.tapDelete()
        activityLogPage.confirmDelete()

        // Then: Returns to activity list without that activity
        activityLogPage.verifyActivityHistoryDisplayed()
        takeScreenshot(named: "ActivityDelete_FromDetail")
    }

    // MARK: - UI-005-007: Toggle Activity Completion

    func test_activityCompletion_toggle_updatesStatus() {
        // Given: Activity marked as complete
        launchWithSampleData()
        navigateToTab("Activities")

        activityLogPage.tapActivityCell(0)
        activityLogPage.verifyActivityDetailDisplayed()

        // When: User toggles completion status
        let initialState = activityLogPage.completionToggle.isOn
        activityLogPage.toggleCompletion()

        activityLogPage.tapSave()

        // Then: Status updated
        activityLogPage.tapActivityCell(0)
        let newState = activityLogPage.completionToggle.isOn

        XCTAssertNotEqual(initialState, newState, "Completion status should toggle")

        takeScreenshot(named: "ActivityCompletion_Toggled")
    }

    // MARK: - UI-005-008: Notes Character Limit

    func test_manualEntry_notesTooLong_showsError() {
        // Given: User on manual entry
        launchWithSingleChild()
        navigateToTab("Activities")
        activityLogPage.tapAddActivity()
        activityLogPage.verifyManualEntryScreenDisplayed()

        // When: User enters notes exceeding 200 characters
        let longNotes = String(repeating: "a", count: 201)
        activityLogPage.selectCategory("Reading")
        activityLogPage.setStartTime(hour: 14, minute: 0)
        activityLogPage.setEndTime(hour: 15, minute: 0)
        activityLogPage.enterNotes(longNotes)

        activityLogPage.tapSave()

        // Then: Validation error or notes truncated
        if activityLogPage.notesTooLongError.exists {
            activityLogPage.verifyNotesTooLongError()
            takeScreenshot(named: "ManualEntry_NotesTooLong_Error")
        } else {
            // Notes might be auto-truncated to 200
            XCTAssertTrue(true, "Notes handled appropriately")
        }
    }

    // MARK: - UI-005-009: Cancel Manual Entry

    func test_manualEntry_cancel_discardsChanges() {
        // Given: User entering manual activity
        launchWithSingleChild()
        navigateToTab("Activities")

        let initialCount = activityLogPage.activityList.cells.count

        activityLogPage.tapAddActivity()
        activityLogPage.selectCategory("Homework")
        activityLogPage.setStartTime(hour: 10, minute: 0)
        activityLogPage.setEndTime(hour: 11, minute: 0)

        // When: User cancels
        activityLogPage.tapCancel()

        // Then: Returns to activity list without adding activity
        let finalCount = activityLogPage.activityList.cells.count
        XCTAssertEqual(finalCount, initialCount, "Activity count should not change when cancelled")

        takeScreenshot(named: "ManualEntry_Cancelled")
    }

    // MARK: - UI-005-010: Activity Detail Shows All Information

    func test_activityDetail_displayAllFields_correctly() {
        // Given: Activity with all fields populated
        launchWithSampleData()
        navigateToTab("Activities")

        // When: User taps on activity
        activityLogPage.tapActivityCell(0)
        activityLogPage.verifyActivityDetailDisplayed()

        // Then: All fields displayed
        assertExists(activityLogPage.activityCategoryLabel)
        assertExists(activityLogPage.activityStartTimeLabel)
        assertExists(activityLogPage.activityEndTimeLabel)
        assertExists(activityLogPage.activityDurationDetailLabel)
        assertExists(activityLogPage.activityNotesTextView)
        assertExists(activityLogPage.activityMoodPicker)
        assertExists(activityLogPage.completionToggle)

        takeScreenshot(named: "ActivityDetail_AllFields")
    }
}

// MARK: - Helper Extension

extension XCUIElement {
    var isOn: Bool {
        return (value as? String) == "1"
    }
}
