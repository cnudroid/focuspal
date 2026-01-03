//
//  TimerViewModelBugTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//
//  TDD tests for reported bugs:
//  - Issue 1: Clock red color disappears on timer start
//  - Issue 2: App exits when timer starts
//  - Issue 3: Activity completion not logging when clicking "finished"
//  - Issue 4: Rewards not being updated

import XCTest
@testable import FocusPal

/// Tests for timer-related bugs
@MainActor
final class TimerViewModelBugTests: XCTestCase {

    var sut: TimerViewModel!
    var mockTimerManager: MultiChildTimerManager!
    var mockActivityService: TestMockActivityService!
    var mockPointsService: TestMockPointsService!
    var mockRewardsService: MockRewardsService!
    var mockNotificationService: MockNotificationService!
    var testChild: Child!
    var testCategory: Category!

    override func setUp() async throws {
        try await super.setUp()

        mockNotificationService = MockNotificationService()
        mockTimerManager = MultiChildTimerManager(notificationService: mockNotificationService)
        mockActivityService = TestMockActivityService()
        mockPointsService = TestMockPointsService()
        mockRewardsService = MockRewardsService()

        testChild = Child(name: "TestChild", age: 8)
        testCategory = Category(
            name: "Reading",
            iconName: "book.fill",
            colorHex: "#FF0000",
            childId: testChild.id,
            recommendedDuration: 25 * 60
        )

        sut = TimerViewModel(
            timerManager: mockTimerManager,
            activityService: mockActivityService,
            pointsService: mockPointsService,
            rewardsService: mockRewardsService,
            currentChild: testChild
        )

        sut.categories = [testCategory]
        sut.selectedCategory = testCategory
    }

    override func tearDown() async throws {
        sut = nil
        mockTimerManager = nil
        mockActivityService = nil
        mockPointsService = nil
        mockRewardsService = nil
        mockNotificationService = nil
        testChild = nil
        testCategory = nil
        try await super.tearDown()
    }

    // MARK: - Issue 1: Clock Red Color Tests

    /// Test that progress stays at 1.0 immediately after starting timer
    func testStartTimer_ProgressShouldBeOne() {
        // Given: Timer is idle
        XCTAssertEqual(sut.timerState, .idle)

        // When: Timer starts
        sut.startTimer()

        // Then: Progress should be 1.0 (full), not 0
        XCTAssertEqual(sut.progress, 1.0, "Progress should be 1.0 when timer just started")
        XCTAssertEqual(sut.timerState, .running)
    }

    /// Test that timer state transitions correctly without intermediate states
    func testStartTimer_StateTransitionsDirectlyToRunning() {
        // Given: Timer is idle
        XCTAssertEqual(sut.timerState, .idle)

        // When: Timer starts
        sut.startTimer()

        // Then: State should be running, not any intermediate state
        XCTAssertEqual(sut.timerState, .running)
        XCTAssertNotEqual(sut.timerState, .completed)
        XCTAssertNotEqual(sut.timerState, .paused)
    }

    // MARK: - Issue 2: App Exit/Crash Tests

    /// Test that starting timer doesn't crash with nil category
    func testStartTimer_WithNoSelectedCategory_DoesNotCrash() {
        // Given: No category selected
        sut.selectedCategory = nil

        // When: Timer starts
        sut.startTimer()

        // Then: Should not crash, timer should remain idle
        XCTAssertEqual(sut.timerState, .idle)
    }

    /// Test that timer manager handles start correctly
    func testStartTimer_TimerManagerReceivesCorrectData() {
        // Given: Valid category selected
        XCTAssertNotNil(sut.selectedCategory)

        // When: Timer starts
        sut.startTimer()

        // Then: Timer manager should have the timer state
        let timerState = mockTimerManager.timerState(for: testChild.id)
        XCTAssertNotNil(timerState, "Timer manager should have state for child")
        XCTAssertEqual(timerState?.categoryId, testCategory.id)
        XCTAssertEqual(timerState?.childId, testChild.id)
    }

    /// Test that multiple rapid start/stop doesn't crash
    func testRapidStartStop_DoesNotCrash() {
        // When: Rapidly starting and stopping
        for _ in 0..<10 {
            sut.startTimer()
            sut.stopTimer()
        }

        // Then: Should not crash, timer should be idle
        XCTAssertEqual(sut.timerState, .idle)
    }

    // MARK: - Issue 3: Activity Completion Not Logging Tests

    /// Test that confirmCompletion logs activity even when category not in current list
    func testConfirmCompletion_LogsActivityUsingStateCategory() async {
        // Given: Timer completed with a category that's stored in the state
        sut.startTimer()

        // Create completed state with known category info
        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-1500),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // Clear categories to simulate the bug where category lookup fails
        sut.categories = []

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: Activity should still be logged (using state's category info)
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1,
                       "Activity should be logged even when categories array doesn't contain the category")
    }

    /// Test that confirmCompletion works with category in the list
    func testConfirmCompletion_WithValidCategory_LogsActivity() async {
        // Given: Timer completed with category in the list
        sut.startTimer()

        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-1500),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: Activity should be logged
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        XCTAssertEqual(mockActivityService.lastLoggedActivity?.isComplete, true)
    }

    /// Test that activity is logged with correct duration
    func testConfirmCompletion_LogsCorrectDuration() async {
        // Given: Timer ran for specific duration
        let elapsedTime: TimeInterval = 1200 // 20 minutes

        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-elapsedTime),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: Logged activity should have approximately correct duration
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        if let loggedActivity = mockActivityService.lastLoggedActivity {
            // Duration should be close to elapsed time (within 2 seconds tolerance)
            let actualDuration = loggedActivity.duration
            XCTAssertEqual(actualDuration, elapsedTime, accuracy: 2.0,
                          "Logged duration should match elapsed time")
        }
    }

    // MARK: - Issue 4: Rewards Not Updating Tests

    /// Test that points are awarded when activity is completed
    func testConfirmCompletion_AwardsPoints() async {
        // Given: Timer completed
        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-1500),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: Points should be awarded
        XCTAssertGreaterThan(mockPointsService.awardCallCount, 0,
                            "Points should be awarded on activity completion")
        XCTAssertEqual(mockPointsService.lastAwardedAmount, 10,
                      "Should award 10 points for completion")
        XCTAssertEqual(mockPointsService.lastAwardedReason, .activityComplete)
    }

    /// Test that points service is called with correct child ID
    func testConfirmCompletion_AwardsPointsToCorrectChild() async {
        // Given: Timer completed
        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-1500),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: Points awarded to correct child
        XCTAssertEqual(mockPointsService.lastAwardedChildId, testChild.id,
                      "Points should be awarded to the correct child")
    }

    // MARK: - Issue 4: Rewards Update Tests

    /// Test that rewards service is called when activity is completed
    /// This is the key test for Issue 4: Rewards not being updated
    func testConfirmCompletion_UpdatesRewardsService() async {
        // Given: Timer completed
        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-1500),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then: Rewards service should be called to add points
        XCTAssertGreaterThan(mockRewardsService.addPointsCallCount, 0,
                            "Rewards service should be called when activity is completed")
    }

    /// Test that rewards service is updated with correct points amount
    func testConfirmCompletion_UpdatesRewardsWithCorrectPoints() async {
        // Given: Timer completed
        let completedState = ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: testCategory.id,
            categoryName: testCategory.name,
            categoryIconName: testCategory.iconName,
            categoryColorHex: testCategory.colorHex,
            startTime: Date().addingTimeInterval(-1500),
            totalDuration: 1500,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then: Rewards should be updated with 10 points
        XCTAssertEqual(mockRewardsService.addPointsCallCount, 1,
                      "Rewards service should be called once")
        XCTAssertEqual(mockRewardsService.mockCurrentWeekReward?.totalPoints, 10,
                      "Rewards should reflect the 10 points earned")
    }
}
