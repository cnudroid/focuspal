//
//  TimerViewModelAchievementTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//
//  Tests for achievement integration in TimerViewModel
//  Verifies that achievements are tracked and notifications are displayed

import XCTest
@testable import FocusPal

/// Tests for achievement unlock tracking and notification display in TimerViewModel
@MainActor
final class TimerViewModelAchievementTests: XCTestCase {

    var sut: TimerViewModel!
    var mockTimerManager: MultiChildTimerManager!
    var mockActivityService: TestMockActivityService!
    var mockAchievementService: TestMockAchievementService!
    var mockNotificationService: MockNotificationService!
    var testChild: Child!
    var testCategory: Category!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize mocks
        mockNotificationService = MockNotificationService()
        mockTimerManager = MultiChildTimerManager(notificationService: mockNotificationService)
        mockActivityService = TestMockActivityService()
        mockAchievementService = TestMockAchievementService()

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
            achievementService: mockAchievementService,
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
        mockAchievementService = nil
        mockNotificationService = nil
        testChild = nil
        testCategory = nil
        try await super.tearDown()
    }

    // MARK: - Timer Completion Achievement Tests

    func testConfirmCompletion_FirstTimer_UnlocksFirstTimerAchievement() async {
        // Given: Timer completed for the first time
        let unlockedAchievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 1
        )
        mockAchievementService.achievementsToReturn = [unlockedAchievement]

        sut.startTimer()
        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should record timer completion with achievement service
        XCTAssertEqual(mockAchievementService.recordTimerCompletionCallCount, 1)
        XCTAssertEqual(mockAchievementService.lastRecordedChildId, testChild.id)

        // And: Should display achievement unlock notification
        XCTAssertEqual(sut.achievementNotifications.count, 1)
        XCTAssertEqual(sut.achievementNotifications.first?.achievement.id, unlockedAchievement.id)
        XCTAssertEqual(sut.achievementNotifications.first?.title, "First Timer")
    }

    func testConfirmCompletion_NoAchievementUnlocked_NoNotificationShown() async {
        // Given: Timer completed but no achievements unlocked
        mockAchievementService.achievementsToReturn = []

        sut.startTimer()
        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should still record timer completion
        XCTAssertEqual(mockAchievementService.recordTimerCompletionCallCount, 1)

        // But: No notification should be shown
        XCTAssertTrue(sut.achievementNotifications.isEmpty)
    }

    func testMarkIncomplete_DoesNotRecordTimerCompletion() async {
        // Given: Timer completed but user didn't finish
        sut.startTimer()
        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState

        // When: User marks as incomplete
        sut.markIncomplete()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should NOT record timer completion achievement
        XCTAssertEqual(mockAchievementService.recordTimerCompletionCallCount, 0)
        XCTAssertTrue(sut.achievementNotifications.isEmpty)
    }

    // MARK: - Category Time Achievement Tests

    func testConfirmCompletion_HomeworkCategory_TracksHomeworkHeroProgress() async {
        // Given: Homework category selected
        let homeworkCategory = Category(
            name: "Homework",
            iconName: "book.circle.fill",
            colorHex: "#FF9500",
            childId: testChild.id,
            recommendedDuration: 30 * 60
        )
        sut.categories = [homeworkCategory]
        sut.selectedCategory = homeworkCategory

        let unlockedAchievement = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 600 // 10 hours
        )
        mockAchievementService.achievementsToReturn = [unlockedAchievement]

        sut.startTimer()
        let completedState = createCompletedState(category: homeworkCategory, duration: 1800) // 30 minutes
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should record category time
        XCTAssertEqual(mockAchievementService.recordCategoryTimeCallCount, 1)
        XCTAssertEqual(mockAchievementService.lastRecordedMinutes, 30)
        XCTAssertEqual(mockAchievementService.lastRecordedCategory?.name, "Homework")
    }

    func testConfirmCompletion_ReadingCategory_TracksReadingChampionProgress() async {
        // Given: Reading category selected
        let readingCategory = Category(
            name: "Reading",
            iconName: "book.fill",
            colorHex: "#FF0000",
            childId: testChild.id,
            recommendedDuration: 20 * 60
        )
        sut.categories = [readingCategory]
        sut.selectedCategory = readingCategory

        let unlockedAchievement = Achievement(
            achievementTypeId: AchievementType.readingChampion.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 300 // 5 hours
        )
        mockAchievementService.achievementsToReturn = [unlockedAchievement]

        sut.startTimer()
        let completedState = createCompletedState(category: readingCategory, duration: 1200) // 20 minutes
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should record category time and unlock achievement
        XCTAssertEqual(mockAchievementService.recordCategoryTimeCallCount, 1)
        XCTAssertEqual(mockAchievementService.lastRecordedMinutes, 20)
        XCTAssertEqual(sut.achievementNotifications.count, 1)
        XCTAssertEqual(sut.achievementNotifications.first?.title, "Reading Champion")
    }

    // MARK: - Early Bird Achievement Tests

    func testConfirmCompletion_EarlyMorningActivity_TracksEarlyBirdProgress() async {
        // Given: Activity started before 8 AM
        let earlyMorningTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!

        let unlockedAchievement = Achievement(
            achievementTypeId: AchievementType.earlyBird.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 5
        )
        mockAchievementService.achievementsToReturn = [unlockedAchievement]

        sut.startTimer()
        let completedState = createCompletedState(startTime: earlyMorningTime)
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should record activity time for early bird achievement
        XCTAssertEqual(mockAchievementService.recordActivityTimeCallCount, 1)
        XCTAssertNotNil(mockAchievementService.lastRecordedStartTime)

        // And: Should display achievement unlock notification
        XCTAssertEqual(sut.achievementNotifications.count, 1)
        XCTAssertEqual(sut.achievementNotifications.first?.title, "Early Bird")
    }

    func testConfirmCompletion_LateActivityAfter8AM_DoesNotTrackEarlyBird() async {
        // Given: Activity started after 8 AM
        let lateTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!

        sut.startTimer()
        let completedState = createCompletedState(startTime: lateTime)
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should still record activity time (service decides if it qualifies)
        XCTAssertEqual(mockAchievementService.recordActivityTimeCallCount, 1)
    }

    // MARK: - Multiple Achievements Tests

    func testConfirmCompletion_UnlocksMultipleAchievements_ShowsAllNotifications() async {
        // Given: Homework category activity that unlocks two achievements
        let homeworkCategory = Category(
            name: "Homework",
            iconName: "book.circle.fill",
            colorHex: "#FF9500",
            childId: testChild.id,
            recommendedDuration: 30 * 60
        )
        sut.categories = [homeworkCategory]
        sut.selectedCategory = homeworkCategory

        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 600
        )
        mockAchievementService.achievementsToReturn = [achievement1, achievement2]

        sut.startTimer()
        let completedState = createCompletedState(category: homeworkCategory)
        sut.pendingCompletionState = completedState

        // When: User confirms completion
        sut.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show notifications for both achievements
        XCTAssertEqual(sut.achievementNotifications.count, 2)
        let titles = sut.achievementNotifications.map { $0.title }
        XCTAssertTrue(titles.contains("First Timer"))
        XCTAssertTrue(titles.contains("Homework Hero"))
    }

    // MARK: - Dismissing Notifications Tests

    func testDismissAchievementNotification_RemovesFromList() async {
        // Given: Achievement notification displayed
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            targetValue: 1
        )
        mockAchievementService.achievementsToReturn = [achievement]

        sut.startTimer()
        let completedState = createCompletedState()
        sut.pendingCompletionState = completedState
        sut.confirmCompletion()

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Verify notification is shown
        XCTAssertEqual(sut.achievementNotifications.count, 1)
        let notification = sut.achievementNotifications.first!

        // When: User dismisses the notification
        sut.dismissAchievementNotification(notification)

        // Then: Notification should be removed
        XCTAssertTrue(sut.achievementNotifications.isEmpty)
    }

    // MARK: - Nil Achievement Service Handling Tests

    func testConfirmCompletion_WithNilAchievementService_DoesNotCrash() async {
        // Given: TimerViewModel with nil achievement service
        let sutWithNilAchievements = TimerViewModel(
            timerManager: mockTimerManager,
            activityService: mockActivityService,
            achievementService: nil,
            currentChild: testChild
        )
        sutWithNilAchievements.categories = [testCategory]
        sutWithNilAchievements.selectedCategory = testCategory
        sutWithNilAchievements.startTimer()

        let completedState = createCompletedState()
        sutWithNilAchievements.pendingCompletionState = completedState

        // When: User confirms completion with nil achievement service
        sutWithNilAchievements.confirmCompletion()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should not crash and activity should still be logged
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        XCTAssertTrue(sutWithNilAchievements.achievementNotifications.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testConfirmCompletion_WhenAchievementServiceThrows_ContinuesGracefully() async {
        // Given: Achievement service that throws errors
        mockAchievementService.shouldThrowError = true
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

        // And: No notification shown due to error
        XCTAssertTrue(sut.achievementNotifications.isEmpty)
    }

    // MARK: - Helper Methods

    private func createCompletedState(
        category: Category? = nil,
        duration: TimeInterval = 1500,
        startTime: Date? = nil
    ) -> ChildTimerState {
        let selectedCategory = category ?? testCategory
        let activityStartTime = startTime ?? Date().addingTimeInterval(-duration)

        return ChildTimerState(
            childId: testChild.id,
            childName: testChild.name,
            categoryId: selectedCategory.id,
            categoryName: selectedCategory.name,
            categoryIconName: selectedCategory.iconName,
            categoryColorHex: selectedCategory.colorHex,
            startTime: activityStartTime,
            totalDuration: duration,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
    }
}

// MARK: - Mock Achievement Service

class TestMockAchievementService: AchievementServiceProtocol {
    var recordTimerCompletionCallCount = 0
    var recordCategoryTimeCallCount = 0
    var recordActivityTimeCallCount = 0
    var lastRecordedChildId: UUID?
    var lastRecordedMinutes: Int?
    var lastRecordedCategory: Category?
    var lastRecordedStartTime: Date?
    var shouldThrowError = false
    var achievementsToReturn: [Achievement] = []

    func recordTimerCompletion(for child: Child) async throws -> [Achievement] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }

        recordTimerCompletionCallCount += 1
        lastRecordedChildId = child.id
        return achievementsToReturn
    }

    func recordCategoryTime(minutes: Int, category: Category, for child: Child) async throws -> [Achievement] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }

        recordCategoryTimeCallCount += 1
        lastRecordedMinutes = minutes
        lastRecordedCategory = category
        return achievementsToReturn
    }

    func recordActivityTime(startTime: Date, for child: Child) async throws -> [Achievement] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }

        recordActivityTimeCallCount += 1
        lastRecordedStartTime = startTime
        return achievementsToReturn
    }

    func initializeAchievements(for child: Child) async throws {}
    func recordStreak(days: Int, for child: Child) async throws -> [Achievement] { [] }
    func recordBalancedWeek(balancedDays: Int, for child: Child) async throws -> [Achievement] { [] }
    func fetchAllAchievements(for child: Child) async throws -> [Achievement] { [] }
    func fetchUnlockedAchievements(for child: Child) async throws -> [Achievement] { [] }
    func fetchLockedAchievements(for child: Child) async throws -> [Achievement] { [] }

    func reset() {
        recordTimerCompletionCallCount = 0
        recordCategoryTimeCallCount = 0
        recordActivityTimeCallCount = 0
        lastRecordedChildId = nil
        lastRecordedMinutes = nil
        lastRecordedCategory = nil
        lastRecordedStartTime = nil
        shouldThrowError = false
        achievementsToReturn = []
    }
}
