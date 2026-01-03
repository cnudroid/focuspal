//
//  TimerPage.swift
//  FocusPalUITests
//
//  Page Object for Timer screen
//

import XCTest

class TimerPage {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Timer Display Elements

    var timerDisplay: XCUIElement {
        app.staticTexts["TimerDisplay"]
    }

    var circularTimerView: XCUIElement {
        app.otherElements["CircularTimerView"]
    }

    var barTimerView: XCUIElement {
        app.otherElements["BarTimerView"]
    }

    var analogTimerView: XCUIElement {
        app.otherElements["AnalogTimerView"]
    }

    // MARK: - Duration Selection Elements

    var durationPicker: XCUIElement {
        app.pickers["DurationPicker"]
    }

    func durationButton(_ minutes: Int) -> XCUIElement {
        app.buttons["\(minutes) min"]
    }

    var customDurationButton: XCUIElement {
        app.buttons["Custom"]
    }

    // MARK: - Category Selection Elements

    var categoryPicker: XCUIElement {
        app.otherElements["CategoryPicker"]
    }

    func categoryButton(_ categoryName: String) -> XCUIElement {
        app.buttons[categoryName]
    }

    var selectedCategoryLabel: XCUIElement {
        app.staticTexts["SelectedCategory"]
    }

    // MARK: - Control Buttons

    var playButton: XCUIElement {
        app.buttons["Play"]
    }

    var pauseButton: XCUIElement {
        app.buttons["Pause"]
    }

    var resumeButton: XCUIElement {
        app.buttons["Resume"]
    }

    var stopButton: XCUIElement {
        app.buttons["Stop"]
    }

    var resetButton: XCUIElement {
        app.buttons["Reset"]
    }

    var extendButton: XCUIElement {
        app.buttons["Extend Time"]
    }

    // MARK: - Timer Mode Elements

    var timerModeSegment: XCUIElement {
        app.segmentedControls["TimerMode"]
    }

    var basicModeButton: XCUIElement {
        timerModeSegment.buttons["Basic"]
    }

    var pomodoroModeButton: XCUIElement {
        timerModeSegment.buttons["Pomodoro"]
    }

    // MARK: - Pomodoro Elements

    var pomodoroSessionCounter: XCUIElement {
        app.staticTexts["PomodoroSessionCounter"]
    }

    var workSessionLabel: XCUIElement {
        app.staticTexts["Work Session"]
    }

    var breakSessionLabel: XCUIElement {
        app.staticTexts["Break Time"]
    }

    var startBreakButton: XCUIElement {
        app.buttons["Start Break"]
    }

    var skipBreakButton: XCUIElement {
        app.buttons["Skip Break"]
    }

    // MARK: - Visualization Mode Elements

    var visualizationModePicker: XCUIElement {
        app.segmentedControls["VisualizationMode"]
    }

    func visualizationModeButton(_ mode: String) -> XCUIElement {
        visualizationModePicker.buttons[mode]
    }

    // MARK: - Completion Elements

    var completionView: XCUIElement {
        app.otherElements["TimerCompletionView"]
    }

    var completionTitle: XCUIElement {
        app.staticTexts["Time's Up!"]
    }

    var markCompleteButton: XCUIElement {
        app.buttons["Mark as Complete"]
    }

    var markIncompleteButton: XCUIElement {
        app.buttons["Mark as Incomplete"]
    }

    var addNotesButton: XCUIElement {
        app.buttons["Add Notes"]
    }

    var startNewTimerButton: XCUIElement {
        app.buttons["Start New Timer"]
    }

    // MARK: - Actions

    func selectDuration(_ minutes: Int) {
        durationButton(minutes).tap()
    }

    func selectCategory(_ categoryName: String) {
        categoryButton(categoryName).tap()
    }

    func tapPlay() {
        playButton.tap()
    }

    func tapPause() {
        pauseButton.tap()
    }

    func tapResume() {
        resumeButton.tap()
    }

    func tapStop() {
        stopButton.tap()
    }

    func tapReset() {
        resetButton.tap()
    }

    func tapExtend() {
        extendButton.tap()
    }

    func selectVisualizationMode(_ mode: String) {
        visualizationModeButton(mode).tap()
    }

    func switchToPomodoroMode() {
        pomodoroModeButton.tap()
    }

    func switchToBasicMode() {
        basicModeButton.tap()
    }

    func tapMarkComplete() {
        markCompleteButton.tap()
    }

    func tapMarkIncomplete() {
        markIncompleteButton.tap()
    }

    func tapStartBreak() {
        startBreakButton.tap()
    }

    func tapSkipBreak() {
        skipBreakButton.tap()
    }

    // MARK: - Verification Methods

    func verifyTimerScreenDisplayed() {
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2), "Timer display should be visible")
        XCTAssertTrue(playButton.exists, "Play button should be visible")
    }

    func verifyTimerRunning() {
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should be visible when timer running")
        XCTAssertTrue(stopButton.exists, "Stop button should be visible when timer running")
    }

    func verifyTimerPaused() {
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 2), "Resume button should be visible when timer paused")
        XCTAssertTrue(stopButton.exists, "Stop button should be visible when timer paused")
    }

    func verifyTimerIdle() {
        XCTAssertTrue(playButton.waitForExistence(timeout: 2), "Play button should be visible when timer idle")
        XCTAssertFalse(pauseButton.exists, "Pause button should not be visible when timer idle")
    }

    func verifyTimerCompleted() {
        XCTAssertTrue(completionView.waitForExistence(timeout: 2), "Completion view should be displayed")
        XCTAssertTrue(markCompleteButton.exists, "Mark complete button should be visible")
    }

    func verifyTimerValue(_ expectedValue: String) {
        XCTAssertEqual(timerDisplay.label, expectedValue, "Timer should display \(expectedValue)")
    }

    func verifySelectedCategory(_ categoryName: String) {
        XCTAssertTrue(selectedCategoryLabel.label.contains(categoryName), "Selected category should be \(categoryName)")
    }

    func verifyPomodoroSessionCount(_ count: Int, total: Int = 4) {
        XCTAssertTrue(pomodoroSessionCounter.label.contains("\(count)/\(total)"), "Pomodoro session should show \(count)/\(total)")
    }

    func verifyWorkSession() {
        XCTAssertTrue(workSessionLabel.exists, "Work session label should be visible")
    }

    func verifyBreakSession() {
        XCTAssertTrue(breakSessionLabel.exists, "Break session label should be visible")
    }

    // MARK: - Complete Flows

    func startBasicTimer(duration: Int, category: String) {
        verifyTimerScreenDisplayed()
        selectDuration(duration)
        selectCategory(category)
        tapPlay()
        verifyTimerRunning()
    }

    func startPomodoroTimer(workMinutes: Int = 25, category: String) {
        verifyTimerScreenDisplayed()
        switchToPomodoroMode()
        selectDuration(workMinutes)
        selectCategory(category)
        tapPlay()
        verifyTimerRunning()
        verifyWorkSession()
    }

    func waitForTimerCompletion(timeout: TimeInterval = 30) {
        XCTAssertTrue(completionView.waitForExistence(timeout: timeout), "Timer should complete within timeout")
    }
}
