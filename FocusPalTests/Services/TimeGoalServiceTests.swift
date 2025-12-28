//
//  TimeGoalServiceTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

// Type alias to disambiguate from Swift Charts' Category
typealias Category = FocusPal.Category

/// Tests for TimeGoalService - Time goal tracking, warnings, and enforcement
final class TimeGoalServiceTests: XCTestCase {

    var sut: TimeGoalService!
    var mockActivityService: MockActivityService!
    var mockNotificationService: TimeGoalTestMockNotificationService!
    var testChild: Child!
    var testCategory: Category!
    var testGoal: TimeGoal!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockActivityService = MockActivityService()
        mockNotificationService = TimeGoalTestMockNotificationService()
        sut = TimeGoalService(
            activityService: mockActivityService,
            notificationService: mockNotificationService
        )

        // Setup test data
        testChild = Child(name: "Test Child", age: 10)
        testCategory = Category(
            name: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            childId: testChild.id
        )
        testGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80,  // Warn at 48 minutes
            isActive: true
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        mockActivityService = nil
        mockNotificationService = nil
        testChild = nil
        testCategory = nil
        testGoal = nil
        try super.tearDownWithError()
    }

    // MARK: - Basic Time Tracking Tests

    func testGetTimeUsedToday_WithNoActivities_ReturnsZero() async throws {
        // Arrange
        mockActivityService.todayActivities = []

        // Act
        let timeUsed = try await sut.getTimeUsedToday(
            categoryId: testCategory.id,
            childId: testChild.id
        )

        // Assert
        XCTAssertEqual(timeUsed, 0, "Time used should be 0 when no activities exist")
    }

    func testGetTimeUsedToday_WithActivities_ReturnsTotalMinutes() async throws {
        // Arrange: 3 activities totaling 45 minutes
        let activities = [
            createActivity(durationMinutes: 20),
            createActivity(durationMinutes: 15),
            createActivity(durationMinutes: 10)
        ]
        mockActivityService.todayActivities = activities

        // Act
        let timeUsed = try await sut.getTimeUsedToday(
            categoryId: testCategory.id,
            childId: testChild.id
        )

        // Assert
        XCTAssertEqual(timeUsed, 45, "Time used should sum all activity durations")
    }

    func testGetTimeUsedToday_OnlyCountsMatchingCategory() async throws {
        // Arrange: Activities for different categories
        let differentCategory = UUID()
        let activities = [
            createActivity(durationMinutes: 20, categoryId: testCategory.id),
            createActivity(durationMinutes: 15, categoryId: differentCategory),
            createActivity(durationMinutes: 10, categoryId: testCategory.id)
        ]
        mockActivityService.todayActivities = activities

        // Act
        let timeUsed = try await sut.getTimeUsedToday(
            categoryId: testCategory.id,
            childId: testChild.id
        )

        // Assert
        XCTAssertEqual(timeUsed, 30, "Should only count activities matching the category")
    }

    // MARK: - Goal Status Tests

    func testCheckGoalStatus_BelowWarningThreshold_ReturnsNormal() async throws {
        // Arrange: 30 minutes used, goal is 60 minutes, warning at 80% (48 minutes)
        mockActivityService.todayActivities = [createActivity(durationMinutes: 30)]

        // Act
        let status = try await sut.checkGoalStatus(goal: testGoal)

        // Assert
        XCTAssertEqual(status, .normal, "Status should be normal when below warning threshold")
    }

    func testCheckGoalStatus_AtWarningThreshold_ReturnsWarning() async throws {
        // Arrange: 48 minutes used (80% of 60 minute goal)
        mockActivityService.todayActivities = [createActivity(durationMinutes: 48)]

        // Act
        let status = try await sut.checkGoalStatus(goal: testGoal)

        // Assert
        XCTAssertEqual(status, .warning, "Status should be warning when at threshold")
    }

    func testCheckGoalStatus_ExceedsGoal_ReturnsExceeded() async throws {
        // Arrange: 65 minutes used, goal is 60 minutes
        mockActivityService.todayActivities = [createActivity(durationMinutes: 65)]

        // Act
        let status = try await sut.checkGoalStatus(goal: testGoal)

        // Assert
        XCTAssertEqual(status, .exceeded, "Status should be exceeded when over goal")
    }

    func testCheckGoalStatus_InactiveGoal_ReturnsNormal() async throws {
        // Arrange: Inactive goal with time exceeded
        let inactiveGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80,
            isActive: false
        )
        mockActivityService.todayActivities = [createActivity(durationMinutes: 70)]

        // Act
        let status = try await sut.checkGoalStatus(goal: inactiveGoal)

        // Assert
        XCTAssertEqual(status, .normal, "Inactive goals should always return normal status")
    }

    // MARK: - Warning Notification Tests

    func testTrackTimeAndNotify_ApproachingThreshold_SendsWarning() async throws {
        // Arrange: Just reached warning threshold
        mockActivityService.todayActivities = [createActivity(durationMinutes: 48)]

        // Act
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )

        // Assert
        XCTAssertEqual(mockNotificationService.timeGoalWarningCalls.count, 1, "Should send one warning notification")
        let call = mockNotificationService.timeGoalWarningCalls[0]
        XCTAssertEqual(call.category, testCategory.name)
        XCTAssertEqual(call.timeUsed, 48)
        XCTAssertEqual(call.goalTime, 60)
    }

    func testTrackTimeAndNotify_BelowThreshold_NoWarning() async throws {
        // Arrange: Below warning threshold
        mockActivityService.todayActivities = [createActivity(durationMinutes: 30)]

        // Act
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )

        // Assert
        XCTAssertEqual(mockNotificationService.timeGoalWarningCalls.count, 0, "Should not send warning when below threshold")
    }

    func testTrackTimeAndNotify_ExceedsGoal_SendsExceededNotification() async throws {
        // Arrange: Exceeded goal
        mockActivityService.todayActivities = [createActivity(durationMinutes: 65)]

        // Act
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )

        // Assert
        XCTAssertEqual(mockNotificationService.timeGoalExceededCalls.count, 1, "Should send exceeded notification")
        let call = mockNotificationService.timeGoalExceededCalls[0]
        XCTAssertEqual(call.category, testCategory.name)
        XCTAssertEqual(call.timeUsed, 65)
        XCTAssertEqual(call.goalTime, 60)
    }

    func testTrackTimeAndNotify_OnlyNotifiesOnce_ForWarning() async throws {
        // Arrange: At warning threshold
        mockActivityService.todayActivities = [createActivity(durationMinutes: 48)]

        // Act: Call twice
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )

        // Assert: Should only notify once per day
        XCTAssertEqual(mockNotificationService.timeGoalWarningCalls.count, 1, "Should only send warning notification once per day")
    }

    func testTrackTimeAndNotify_OnlyNotifiesOnce_ForExceeded() async throws {
        // Arrange: Exceeded goal
        mockActivityService.todayActivities = [createActivity(durationMinutes: 65)]

        // Act: Call twice
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )

        // Assert: Should only notify once per day
        XCTAssertEqual(mockNotificationService.timeGoalExceededCalls.count, 1, "Should only send exceeded notification once per day")
    }

    // MARK: - Daily Reset Tests

    func testResetDailyTracking_ClearsNotificationFlags() async throws {
        // Arrange: Send warning and exceeded notifications
        mockActivityService.todayActivities = [createActivity(durationMinutes: 65)]
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )
        XCTAssertEqual(mockNotificationService.timeGoalExceededCalls.count, 1, "Precondition: notification sent")

        // Act: Reset daily tracking
        sut.resetDailyTracking()

        // Act again: Should now send notification again
        try await sut.trackTimeAndNotify(
            categoryId: testCategory.id,
            childId: testChild.id,
            category: testCategory,
            goal: testGoal
        )

        // Assert: Should have sent notification again after reset
        XCTAssertEqual(mockNotificationService.timeGoalExceededCalls.count, 2, "Should send notification again after daily reset")
    }

    func testResetDailyTracking_ScheduledAtMidnight() async throws {
        // This test verifies that the service sets up a timer for midnight reset
        // In production, this would use Timer or background tasks

        // Arrange: Create service
        let service = TimeGoalService(
            activityService: mockActivityService,
            notificationService: mockNotificationService
        )

        // Act: Check if midnight reset is scheduled
        let hasMidnightReset = service.hasMidnightResetScheduled()

        // Assert
        XCTAssertTrue(hasMidnightReset, "Service should schedule midnight reset on initialization")
    }

    // MARK: - Progress Calculation Tests

    func testCalculateProgress_BelowGoal_ReturnsCorrectPercentage() async throws {
        // Arrange: 30 minutes of 60 minute goal = 50%
        mockActivityService.todayActivities = [createActivity(durationMinutes: 30)]

        // Act
        let progress = try await sut.calculateProgress(goal: testGoal)

        // Assert
        XCTAssertEqual(progress, 50.0, accuracy: 0.1, "Progress should be 50%")
    }

    func testCalculateProgress_ExceedsGoal_CapsAt100() async throws {
        // Arrange: 90 minutes of 60 minute goal = 150%, but capped at 100%
        mockActivityService.todayActivities = [createActivity(durationMinutes: 90)]

        // Act
        let progress = try await sut.calculateProgress(goal: testGoal)

        // Assert
        XCTAssertEqual(progress, 100.0, accuracy: 0.1, "Progress should cap at 100%")
    }

    // MARK: - Helper Methods

    private func createActivity(
        durationMinutes: Int,
        categoryId: UUID? = nil,
        childId: UUID? = nil
    ) -> Activity {
        let category = categoryId ?? testCategory.id
        let child = childId ?? testChild.id
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-TimeInterval(durationMinutes * 60))

        return Activity(
            categoryId: category,
            childId: child,
            startTime: startTime,
            endTime: endTime
        )
    }
}

// MARK: - Mock Activity Service

class MockActivityService: ActivityServiceProtocol {
    var todayActivities: [Activity] = []
    var aggregates: [CategoryAggregate] = []

    func logActivity(category: Category, duration: TimeInterval, child: Child, isComplete: Bool = true) async throws -> Activity {
        fatalError("Not implemented for these tests")
    }

    func fetchTodayActivities(for child: Child) async throws -> [Activity] {
        return todayActivities
    }

    func fetchActivities(for child: Child, dateRange: DateInterval) async throws -> [Activity] {
        return todayActivities
    }

    func updateActivity(_ activity: Activity) async throws -> Activity {
        fatalError("Not implemented for these tests")
    }

    func deleteActivity(_ activityId: UUID) async throws {
        fatalError("Not implemented for these tests")
    }

    func calculateDailyAggregates(for child: Child, date: Date) async throws -> [CategoryAggregate] {
        return aggregates
    }
}

// MARK: - Mock Notification Service

class TimeGoalTestMockNotificationService: NotificationServiceProtocol {
    struct TimeGoalWarningCall {
        let category: String
        let timeUsed: Int
        let goalTime: Int
    }

    struct TimeGoalExceededCall {
        let category: String
        let timeUsed: Int
        let goalTime: Int
    }

    var timeGoalWarningCalls: [TimeGoalWarningCall] = []
    var timeGoalExceededCalls: [TimeGoalExceededCall] = []

    func requestAuthorization() async throws -> Bool {
        return true
    }

    func checkAuthorizationStatus() async -> NotificationAuthorizationStatus {
        return .authorized
    }

    func scheduleTimerCompletion(in duration: TimeInterval, categoryName: String) {}
    func scheduleFiveMinuteWarning(in duration: TimeInterval, categoryName: String) {}
    func scheduleOneMinuteWarning(in duration: TimeInterval, categoryName: String) {}
    func cancelTimerNotifications() {}
    func scheduleDailyGoalReminder(at time: DateComponents, childName: String) {}
    func scheduleGoalExceededWarning(category: String, timeUsed: Int, goalTime: Int) {}
    func scheduleGoalApproachingWarning(category: String, timeUsed: Int, goalTime: Int) {}
    func scheduleStreakCelebration(streakDays: Int, childName: String) {}
    func scheduleStreakReminder(streakDays: Int, childName: String, at time: DateComponents) {}
    func scheduleStreakEndedNotification(previousStreak: Int, childName: String) {}

    func scheduleTimeGoalWarning(category: String, timeUsed: Int, goalTime: Int) {
        timeGoalWarningCalls.append(TimeGoalWarningCall(
            category: category,
            timeUsed: timeUsed,
            goalTime: goalTime
        ))
    }

    func scheduleTimeGoalExceeded(category: String, timeUsed: Int, goalTime: Int) {
        timeGoalExceededCalls.append(TimeGoalExceededCall(
            category: category,
            timeUsed: timeUsed,
            goalTime: goalTime
        ))
    }

    func scheduleAchievementUnlock(achievement: Achievement) {}
    func cancelAllNotifications() {}
    func cancelNotifications(withIdentifier identifier: String) {}
}
