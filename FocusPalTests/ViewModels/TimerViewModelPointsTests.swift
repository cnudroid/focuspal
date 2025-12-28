//
//  TimerViewModelPointsTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//
//  Tests for points integration in TimerViewModel

import XCTest
@testable import FocusPal

/// Tests for points logic integration in TimerViewModel
@MainActor
final class TimerViewModelPointsTests: XCTestCase {

    var sut: TimerViewModel!
    var mockTimerManager: MultiChildTimerManager!
    var mockActivityService: TestMockActivityService!
    var mockPointsService: TestMockPointsService!
    var mockNotificationService: MockNotificationService!
    var testChild: Child!
    var testCategory: Category!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize mocks
        mockNotificationService = MockNotificationService()
        mockTimerManager = MultiChildTimerManager(notificationService: mockNotificationService)
        mockActivityService = TestMockActivityService()
        mockPointsService = TestMockPointsService()

        // Create test data
        testChild = Child(name: "TestChild", age: 8)
        testCategory = Category(
            name: "Reading",
            iconName: "book.fill",
            colorHex: "#FF0000",
            childId: testChild.id,
            recommendedDuration: 25 * 60 // 25 minutes
        )

        // Initialize SUT with mocks
        sut = TimerViewModel(
            timerManager: mockTimerManager,
            activityService: mockActivityService,
            pointsService: mockPointsService,
            currentChild: testChild
        )

        // Add test category to categories array and select it
        sut.categories = [testCategory]
        sut.selectedCategory = testCategory
    }

    override func tearDown() async throws {
        sut = nil
        mockTimerManager = nil
        mockActivityService = nil
        mockPointsService = nil
        mockNotificationService = nil
        testChild = nil
        testCategory = nil
        try await super.tearDown()
    }

    // MARK: - Activity Completion Tests (Points Awarded)

    func testConfirmCompletion_AwardsActivityCompletePoints() async {
        // Given: Timer completed and user confirmed completion
        sut.startTimer()

        // Simulate timer completion
        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then: Should award 10 points for activity completion
        XCTAssertEqual(mockPointsService.awardCallCount, 1)
        XCTAssertEqual(mockPointsService.lastAwardedAmount, 10)
        XCTAssertEqual(mockPointsService.lastAwardedReason, .activityComplete)
        XCTAssertEqual(mockPointsService.lastAwardedChildId, testChild.id)
        XCTAssertNotNil(mockPointsService.lastAwardedActivityId)
    }

    func testMarkIncomplete_DeductsActivityIncompletePoints() async {
        // Given: Timer completed but user didn't finish activity
        sut.startTimer()

        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState

        // When: User marks as incomplete
        sut.markIncomplete()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should deduct 5 points for incomplete activity
        XCTAssertEqual(mockPointsService.deductCallCount, 1)
        XCTAssertEqual(mockPointsService.lastDeductedAmount, 5)
        XCTAssertEqual(mockPointsService.lastDeductedReason, .activityIncomplete)
        XCTAssertEqual(mockPointsService.lastDeductedChildId, testChild.id)
    }

    // MARK: - Three Strike Penalty Tests

    func testThreeConsecutiveIncompletes_AppliesThreeStrikePenalty() async {
        // Given: User has marked 2 activities incomplete already
        let state1 = createCompletedState()
        sut.pendingCompletionState = state1
        sut.markIncomplete()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let state2 = createCompletedState()
        sut.pendingCompletionState = state2
        sut.markIncomplete()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Reset deduct count to track only the third incomplete
        let previousDeductCount = mockPointsService.deductCallCount

        // When: User marks third activity incomplete
        let state3 = createCompletedState()
        sut.pendingCompletionState = state3
        sut.markIncomplete()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should deduct 5 points for incomplete AND apply 15 point penalty
        XCTAssertEqual(mockPointsService.deductCallCount, previousDeductCount + 2)

        // Verify the three strike penalty was applied
        let hasThreeStrikePenalty = mockPointsService.allDeductions.contains { transaction in
            transaction.reason == .threeStrikePenalty && transaction.amount == 15
        }
        XCTAssertTrue(hasThreeStrikePenalty, "Should apply three strike penalty after 3 consecutive incompletes")
    }

    func testCompletedActivity_ResetsIncompleteCounter() async {
        // Given: User has marked 2 activities incomplete
        let state1 = createCompletedState()
        sut.pendingCompletionState = state1
        sut.markIncomplete()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let state2 = createCompletedState()
        sut.pendingCompletionState = state2
        sut.markIncomplete()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When: User completes an activity
        let state3 = createCompletedState()
        sut.pendingCompletionState = state3
        sut.confirmCompletion()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Counter should reset, so next incomplete won't trigger penalty
        let state4 = createCompletedState()
        sut.pendingCompletionState = state4
        sut.markIncomplete()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should not have three strike penalty (only incomplete deduction)
        let hasThreeStrikePenalty = mockPointsService.allDeductions.contains { transaction in
            transaction.reason == .threeStrikePenalty
        }
        XCTAssertFalse(hasThreeStrikePenalty, "Should NOT apply penalty after counter was reset")
    }

    // MARK: - Early Finish Bonus Tests

    func testCompleteEarly_UnderEightyPercent_AwardsEarlyFinishBonus() async {
        // Given: Timer running for a 25-minute activity
        sut.startTimer()

        // Start a timer that will have less than 80% elapsed time when completed early
        mockTimerManager.startTimer(for: testChild, category: testCategory, duration: 1500)

        // When: User completes early
        sut.completeEarly()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should award activity complete points AND early finish bonus
        XCTAssertEqual(mockPointsService.awardCallCount, 2, "Should award both completion and early finish bonus")

        let hasEarlyBonus = mockPointsService.allAwards.contains { transaction in
            transaction.reason == .earlyFinishBonus && transaction.amount == 5
        }
        XCTAssertTrue(hasEarlyBonus, "Should award early finish bonus for completing in <80% of time")
    }

    func testCompleteEarly_AlwaysAwardsEarlyBonus_WhenElapsedIsMinimal() async {
        // Given: Timer running for a 25-minute activity
        sut.startTimer()

        // Start a timer - since we complete immediately, elapsed time is minimal (<80%)
        mockTimerManager.startTimer(for: testChild, category: testCategory, duration: 1500)

        // When: User completes early (elapsed time is very small)
        sut.completeEarly()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should award both completion points AND early bonus (since elapsed is minimal)
        XCTAssertEqual(mockPointsService.awardCallCount, 2, "Should award both completion and early bonus")

        let hasCompletionPoints = mockPointsService.allAwards.contains { transaction in
            transaction.reason == .activityComplete && transaction.amount == 10
        }
        XCTAssertTrue(hasCompletionPoints, "Should award completion points")

        let hasEarlyBonus = mockPointsService.allAwards.contains { transaction in
            transaction.reason == .earlyFinishBonus && transaction.amount == 5
        }
        XCTAssertTrue(hasEarlyBonus, "Should award early finish bonus for completing quickly")
    }

    // MARK: - Nil PointsService Handling Tests

    func testConfirmCompletion_WithNilPointsService_DoesNotCrash() async {
        // Given: TimerViewModel with nil points service
        let sutWithNilPoints = TimerViewModel(
            timerManager: mockTimerManager,
            activityService: mockActivityService,
            pointsService: nil,
            currentChild: testChild
        )
        // Add test category to categories array
        sutWithNilPoints.categories = [testCategory]
        sutWithNilPoints.selectedCategory = testCategory
        sutWithNilPoints.startTimer()

        let completedState = createCompletedState()
        sutWithNilPoints.pendingCompletionState = completedState

        // When: User confirms completion with nil points service
        sutWithNilPoints.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should not crash and activity should still be logged
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        XCTAssertEqual(mockActivityService.lastLoggedActivity?.isComplete, true)
    }

    func testMarkIncomplete_WithNilPointsService_DoesNotCrash() async {
        // Given: TimerViewModel with nil points service
        let sutWithNilPoints = TimerViewModel(
            timerManager: mockTimerManager,
            activityService: mockActivityService,
            pointsService: nil,
            currentChild: testChild
        )
        // Add test category to categories array
        sutWithNilPoints.categories = [testCategory]
        sutWithNilPoints.selectedCategory = testCategory
        sutWithNilPoints.startTimer()

        let completedState = createCompletedState()
        sutWithNilPoints.pendingCompletionState = completedState

        // When: User marks incomplete with nil points service
        sutWithNilPoints.markIncomplete()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should not crash and activity should still be logged
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        XCTAssertEqual(mockActivityService.lastLoggedActivity?.isComplete, false)
    }

    // MARK: - Error Handling Tests

    func testConfirmCompletion_WhenPointsServiceThrows_ContinuesGracefully() async {
        // Given: Points service that throws errors
        mockPointsService.shouldThrowError = true
        sut.startTimer()

        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should continue gracefully and still log activity
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        XCTAssertEqual(mockActivityService.lastLoggedActivity?.isComplete, true)
    }

    // MARK: - Helper Methods

    private func createCompletedState() -> ChildTimerState {
        return ChildTimerState(
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
    }
}

// MARK: - Mock Points Service

class TestMockPointsService: PointsServiceProtocol {
    var awardCallCount = 0
    var deductCallCount = 0
    var lastAwardedChildId: UUID?
    var lastAwardedAmount: Int?
    var lastAwardedReason: PointsReason?
    var lastAwardedActivityId: UUID?
    var lastDeductedChildId: UUID?
    var lastDeductedAmount: Int?
    var lastDeductedReason: PointsReason?
    var shouldThrowError = false

    var allAwards: [(childId: UUID, amount: Int, reason: PointsReason, activityId: UUID?)] = []
    var allDeductions: [(childId: UUID, amount: Int, reason: PointsReason)] = []

    func awardPoints(childId: UUID, amount: Int, reason: PointsReason, activityId: UUID?) async throws {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }

        awardCallCount += 1
        lastAwardedChildId = childId
        lastAwardedAmount = amount
        lastAwardedReason = reason
        lastAwardedActivityId = activityId
        allAwards.append((childId, amount, reason, activityId))
    }

    func deductPoints(childId: UUID, amount: Int, reason: PointsReason) async throws {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }

        deductCallCount += 1
        lastDeductedChildId = childId
        lastDeductedAmount = amount
        lastDeductedReason = reason
        allDeductions.append((childId, amount, reason))
    }

    func getTodayPoints(for childId: UUID) async throws -> ChildPoints {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }

        return ChildPoints(
            childId: childId,
            date: Date(),
            pointsEarned: 0,
            pointsDeducted: 0,
            bonusPoints: 0
        )
    }

    func getWeeklyPoints(for childId: UUID) async throws -> Int {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return 0
    }

    func getTotalPoints(for childId: UUID) async throws -> Int {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return 0
    }

    func getTransactionHistory(for childId: UUID, limit: Int) async throws -> [PointsTransaction] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return []
    }

    func reset() {
        awardCallCount = 0
        deductCallCount = 0
        lastAwardedChildId = nil
        lastAwardedAmount = nil
        lastAwardedReason = nil
        lastAwardedActivityId = nil
        lastDeductedChildId = nil
        lastDeductedAmount = nil
        lastDeductedReason = nil
        shouldThrowError = false
        allAwards = []
        allDeductions = []
    }
}
