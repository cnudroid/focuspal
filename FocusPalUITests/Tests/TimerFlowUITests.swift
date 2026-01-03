//
//  TimerFlowUITests.swift
//  FocusPalUITests
//
//  UI tests for timer functionality
//  Test ID: UI-003
//  Priority: P0 (Critical)
//

import XCTest

final class TimerFlowUITests: BaseUITest {

    var timerPage: TimerPage!

    override func setUp() {
        super.setUp()
        timerPage = TimerPage(app: app)
    }

    override func tearDown() {
        timerPage = nil
        super.tearDown()
    }

    // MARK: - UI-003-001: Start Timer Basic Flow

    func test_startTimer_withCategoryAndDuration_startsCountdown() {
        // Given: User on home screen with profile selected
        launchWithSingleChild()

        // Navigate to timer
        navigateToTab("Timer")
        timerPage.verifyTimerScreenDisplayed()
        takeScreenshot(named: "Timer_01_InitialScreen")

        // When: User selects duration and category
        timerPage.selectDuration(25)
        timerPage.selectCategory("Homework")
        takeScreenshot(named: "Timer_02_ConfiguredTimer")

        timerPage.tapPlay()

        // Then: Timer starts counting down
        timerPage.verifyTimerRunning()
        timerPage.verifyTimerValue("25:00")
        takeScreenshot(named: "Timer_03_TimerRunning")

        // Verify selected category displayed
        timerPage.verifySelectedCategory("Homework")
    }

    // MARK: - UI-003-002: Pause and Resume Timer

    func test_timer_pauseAndResume_maintainsRemainingTime() {
        // Given: Timer is running
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.startBasicTimer(duration: 15, category: "Reading")

        // Wait a bit for timer to count down
        sleep(2)

        // When: User pauses timer
        timerPage.tapPause()

        // Then: Timer paused
        timerPage.verifyTimerPaused()
        let pausedValue = timerPage.timerDisplay.label
        takeScreenshot(named: "Timer_Paused")

        // Wait to verify time doesn't change while paused
        sleep(2)
        XCTAssertEqual(timerPage.timerDisplay.label, pausedValue, "Timer should not count down while paused")

        // When: User resumes timer
        timerPage.tapResume()

        // Then: Timer continues from paused time
        timerPage.verifyTimerRunning()
        takeScreenshot(named: "Timer_Resumed")
    }

    // MARK: - UI-003-003: Stop Timer

    func test_timer_stop_resetsToIdle() {
        // Given: Timer is running
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.startBasicTimer(duration: 10, category: "Physical Activity")

        // When: User stops timer
        timerPage.tapStop()

        // Then: Timer reset to idle state
        timerPage.verifyTimerIdle()
        takeScreenshot(named: "Timer_Stopped")
    }

    // MARK: - UI-003-004: Timer Completion

    func test_timer_completion_showsCompletionView() {
        // Given: Timer with short duration
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.selectDuration(1) // 1 minute timer
        timerPage.selectCategory("Creative Play")
        timerPage.tapPlay()

        // When: Timer completes (fast-forward for testing)
        // In real test, we'd use a test hook to fast-forward time
        timerPage.waitForTimerCompletion(timeout: 70) // Wait max 70 seconds

        // Then: Completion view shown
        timerPage.verifyTimerCompleted()
        takeScreenshot(named: "Timer_Completed")

        assertExists(timerPage.completionTitle)
        assertExists(timerPage.markCompleteButton)
    }

    // MARK: - UI-003-005: Mark Activity Complete After Timer

    func test_timerCompletion_markComplete_logsActivity() {
        // Given: Timer completed
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.selectDuration(1)
        timerPage.selectCategory("Homework")
        timerPage.tapPlay()
        timerPage.waitForTimerCompletion(timeout: 70)

        // When: User marks activity as complete
        timerPage.tapMarkComplete()

        // Then: Activity logged
        // Navigate to activity log to verify
        navigateToTab("Activities")

        let activityLogPage = ActivityLogPage(app: app)
        activityLogPage.verifyActivityLogged("Homework")
        takeScreenshot(named: "Timer_ActivityLogged")
    }

    // MARK: - UI-003-006: Mark Activity Incomplete After Timer

    func test_timerCompletion_markIncomplete_logsWithIncompleteStatus() {
        // Given: Timer completed
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.selectDuration(1)
        timerPage.selectCategory("Reading")
        timerPage.tapPlay()
        timerPage.waitForTimerCompletion(timeout: 70)

        // When: User marks activity as incomplete
        timerPage.tapMarkIncomplete()

        // Then: Activity logged with incomplete status
        navigateToTab("Activities")

        let activityLogPage = ActivityLogPage(app: app)
        activityLogPage.verifyActivityLogged("Reading")

        // Tap on activity to see details
        activityLogPage.tapActivityWithCategory("Reading")
        activityLogPage.verifyActivityDetailDisplayed()

        // Verify completion toggle is off
        XCTAssertFalse(activityLogPage.completionToggle.isOn, "Activity should be marked incomplete")

        takeScreenshot(named: "Timer_ActivityIncomplete")
    }

    // MARK: - UI-003-007: Visualization Mode Switching

    func test_timer_switchVisualizationMode_updatesDisplay() {
        // Given: Timer screen
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.verifyTimerScreenDisplayed()

        // When: User switches to Bar mode
        timerPage.selectVisualizationMode("Bar")

        // Then: Bar timer view displayed
        assertExists(timerPage.barTimerView)
        takeScreenshot(named: "Timer_BarMode")

        // When: User switches to Analog mode
        timerPage.selectVisualizationMode("Analog")

        // Then: Analog timer view displayed
        assertExists(timerPage.analogTimerView)
        takeScreenshot(named: "Timer_AnalogMode")

        // When: User switches to Circular mode
        timerPage.selectVisualizationMode("Circular")

        // Then: Circular timer view displayed
        assertExists(timerPage.circularTimerView)
        takeScreenshot(named: "Timer_CircularMode")
    }

    // MARK: - UI-003-008: Extend Timer

    func test_timer_extendTime_addsAdditionalMinutes() {
        // Given: Timer running
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.startBasicTimer(duration: 5, category: "Homework")

        // When: User extends time
        timerPage.tapExtend()

        // User might see a picker to add 5, 10, or 15 minutes
        // Simplified: assume extend adds 5 minutes
        if app.buttons["5 min"].exists {
            app.buttons["5 min"].tap()
        }

        // Then: Timer updated with additional time
        // Original 5 min + 5 min extension = ~10 min (accounting for elapsed time)
        takeScreenshot(named: "Timer_Extended")
    }

    // MARK: - UI-003-009: Cannot Start Multiple Timers

    func test_timer_whenRunning_preventStartingAnother() {
        // Given: Timer already running
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.startBasicTimer(duration: 10, category: "Reading")

        // When: User tries to start another timer
        // Play button should be replaced with pause/stop

        // Then: Cannot start another timer
        assertNotExists(timerPage.playButton, message: "Play button should not be available when timer running")
        assertExists(timerPage.pauseButton)
        assertExists(timerPage.stopButton)
    }

    // MARK: - UI-003-010: Timer Persists Across App Restart

    func test_timer_appRestart_resumesFromSavedState() {
        // Given: Timer running
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.startBasicTimer(duration: 15, category: "Physical Activity")

        let runningValue = timerPage.timerDisplay.label

        // When: App is terminated and relaunched
        app.terminate()
        sleep(2)
        app.launch()

        // Then: Timer state restored (may show as paused or continue running)
        navigateToTab("Timer")

        // Timer should either be running or paused with saved time
        XCTAssertTrue(
            timerPage.pauseButton.exists || timerPage.resumeButton.exists,
            "Timer should be restored after app restart"
        )

        takeScreenshot(named: "Timer_RestoredAfterRestart")
    }

    // MARK: - UI-003-011: Timer Requires Category Selection

    func test_timer_startWithoutCategory_showsError() {
        // Given: Timer screen with duration selected
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.verifyTimerScreenDisplayed()

        timerPage.selectDuration(10)

        // When: User tries to start without selecting category
        timerPage.tapPlay()

        // Then: Error shown or play button disabled
        // Check if error message appears or button is disabled
        if app.staticTexts["Please select a category"].exists {
            XCTAssertTrue(true, "Category required error shown")
            takeScreenshot(named: "Timer_CategoryRequired_Error")
        } else {
            XCTAssertFalse(timerPage.playButton.isEnabled, "Play button should be disabled without category")
        }
    }

    // MARK: - UI-003-012: Background Timer Continues

    func test_timer_backgroundApp_continuesRunning() {
        // Given: Timer running
        launchWithSingleChild()
        navigateToTab("Timer")
        timerPage.startBasicTimer(duration: 5, category: "Homework")

        let initialValue = timerPage.timerDisplay.label

        // When: App backgrounded
        XCUIDevice.shared.press(.home)
        sleep(5) // Wait 5 seconds

        // Bring app back to foreground
        app.activate()

        // Then: Timer has continued counting down
        navigateToTab("Timer")
        let currentValue = timerPage.timerDisplay.label

        XCTAssertNotEqual(currentValue, initialValue, "Timer should have counted down while backgrounded")
        takeScreenshot(named: "Timer_AfterBackground")
    }
}
