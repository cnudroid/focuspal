//
//  HomeViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

@MainActor
final class HomeViewModelTests: XCTestCase {

    var sut: HomeViewModel!
    var mockActivityService: MockActivityService!
    var mockCategoryService: MockCategoryService!
    var testChild: Child!
    var testCategory: Category!

    override func setUp() async throws {
        try await super.setUp()

        testChild = TestData.makeChild(name: "Emma", age: 8)
        testCategory = TestData.makeCategory(
            name: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            childId: testChild.id
        )

        mockActivityService = MockActivityService()
        mockCategoryService = MockCategoryService()
        mockCategoryService.mockCategories = [testCategory]

        sut = HomeViewModel(
            activityService: mockActivityService,
            categoryService: mockCategoryService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockActivityService = nil
        mockCategoryService = nil
        testChild = nil
        testCategory = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Given: A newly initialized view model

        // Then: Initial state should be correct
        XCTAssertEqual(sut.todayStats.totalMinutes, 0)
        XCTAssertEqual(sut.todayStats.activitiesCount, 0)
        XCTAssertEqual(sut.todayActivities.count, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.currentChild)
        XCTAssertEqual(sut.todayGoalMinutes, 0)
        XCTAssertEqual(sut.currentStreak, 0)
        XCTAssertEqual(sut.todayAchievements.count, 0)
    }

    // MARK: - Load Data Tests

    func testLoadData_WithNoActivities_LoadsEmptyState() async {
        // Given: Mock service returns no activities
        mockActivityService.mockActivities = []

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: State should be empty
        XCTAssertEqual(sut.todayActivities.count, 0)
        XCTAssertEqual(sut.todayStats.totalMinutes, 0)
        XCTAssertEqual(sut.todayStats.activitiesCount, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(mockActivityService.fetchTodayCallCount, 1)
    }

    func testLoadData_WithMultipleActivities_LoadsCorrectData() async {
        // Given: Mock service returns multiple activities
        let now = Date()
        let activity1 = TestData.makeActivity(
            categoryId: testCategory.id,
            childId: testChild.id,
            startTime: now.addingTimeInterval(-3600),
            endTime: now.addingTimeInterval(-2700) // 15 minutes
        )
        let activity2 = TestData.makeActivity(
            categoryId: testCategory.id,
            childId: testChild.id,
            startTime: now.addingTimeInterval(-1800),
            endTime: now.addingTimeInterval(-900) // 15 minutes
        )
        mockActivityService.mockActivities = [activity1, activity2]

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: State should reflect loaded activities
        XCTAssertEqual(sut.todayActivities.count, 2)
        XCTAssertEqual(sut.todayStats.totalMinutes, 30)
        XCTAssertEqual(sut.todayStats.activitiesCount, 2)
        XCTAssertFalse(sut.isLoading)

        // Verify activity display items are correctly populated
        let firstItem = sut.todayActivities.first!
        XCTAssertEqual(firstItem.categoryName, "Homework")
        XCTAssertEqual(firstItem.iconName, "book.fill")
        XCTAssertEqual(firstItem.colorHex, "#4A90D9")
        XCTAssertEqual(firstItem.durationMinutes, 15)
    }

    func testLoadData_SetsLoadingState() async {
        // Given: Mock service with delay
        mockActivityService.mockActivities = []

        // When: Loading data starts
        let loadTask = Task {
            await sut.loadData(for: testChild)
        }

        // Then: Loading state should be true during loading
        // Note: This is a simplified test - in real scenario we'd need to check
        // loading state before the task completes

        await loadTask.value
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadData_WithError_SetsErrorMessage() async {
        // Given: Mock service that throws an error
        enum TestError: Error {
            case failed
        }
        mockActivityService.mockError = TestError.failed

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Error message should be set
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.todayActivities.count, 0)
    }

    func testLoadData_WithCategories_PopulatesCategoryInfo() async {
        // Given: Activity with associated category
        let activity = TestData.makeActivity(
            categoryId: testCategory.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(-2700)
        )
        mockActivityService.mockActivities = [activity]

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Activity display items should include category information
        let displayItem = sut.todayActivities.first!
        XCTAssertEqual(displayItem.categoryName, testCategory.name)
        XCTAssertEqual(displayItem.iconName, testCategory.iconName)
        XCTAssertEqual(displayItem.colorHex, testCategory.colorHex)
    }

    // MARK: - Stats Calculation Tests

    func testCalculateTodayStats_WithNoActivities_ReturnsZeroStats() async {
        // Given: No activities
        mockActivityService.mockActivities = []

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Stats should be zero
        XCTAssertEqual(sut.todayStats.totalMinutes, 0)
        XCTAssertEqual(sut.todayStats.activitiesCount, 0)
        XCTAssertEqual(sut.todayStats.balanceScore, 0)
    }

    func testCalculateTodayStats_WithSingleActivity_CalculatesCorrectly() async {
        // Given: One activity of 45 minutes
        let activity = TestData.makeActivity(
            categoryId: testCategory.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-2700),
            endTime: Date()
        )
        mockActivityService.mockActivities = [activity]

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Stats should reflect single activity
        XCTAssertEqual(sut.todayStats.totalMinutes, 45)
        XCTAssertEqual(sut.todayStats.activitiesCount, 1)
    }

    func testCalculateTodayStats_WithMultipleActivities_SumsDurations() async {
        // Given: Multiple activities with different durations
        let activities = [
            TestData.makeActivity(
                categoryId: testCategory.id,
                childId: testChild.id,
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-5400) // 30 min
            ),
            TestData.makeActivity(
                categoryId: testCategory.id,
                childId: testChild.id,
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-1800) // 30 min
            )
        ]
        mockActivityService.mockActivities = activities

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Stats should sum all activities
        XCTAssertEqual(sut.todayStats.totalMinutes, 60)
        XCTAssertEqual(sut.todayStats.activitiesCount, 2)
    }

    // MARK: - Child Information Tests

    func testLoadData_StoresChildInformation() async {
        // Given: A child with specific properties
        let child = TestData.makeChild(name: "Alex", age: 10, avatarId: "avatar_1")

        // When: Loading data
        await sut.loadData(for: child)

        // Then: Child information should be stored
        XCTAssertEqual(sut.currentChild?.name, "Alex")
        XCTAssertEqual(sut.currentChild?.age, 10)
        XCTAssertEqual(sut.currentChild?.avatarId, "avatar_1")
    }

    func testGreetingText_ReturnsCorrectGreeting() {
        // Given: A child
        let child = TestData.makeChild(name: "Sophie")
        sut.currentChild = child

        // When: Getting greeting text
        let greeting = sut.greetingText

        // Then: Greeting should include child's name
        XCTAssertTrue(greeting.contains("Sophie"))
    }

    // MARK: - Goal Progress Tests

    func testLoadData_WithGoals_CalculatesProgress() async {
        // Given: Activities and daily goal
        let activities = [
            TestData.makeActivity(
                categoryId: testCategory.id,
                childId: testChild.id,
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-1800) // 30 min
            )
        ]
        mockActivityService.mockActivities = activities
        sut.todayGoalMinutes = 60 // Goal of 60 minutes

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Progress should be calculated
        XCTAssertEqual(sut.goalProgress, 0.5) // 30/60 = 0.5
    }

    func testGoalProgress_WithNoGoal_ReturnsZero() {
        // Given: No daily goal set
        sut.todayGoalMinutes = 0
        sut.todayStats.totalMinutes = 30

        // When: Getting goal progress
        let progress = sut.goalProgress

        // Then: Progress should be zero
        XCTAssertEqual(progress, 0.0)
    }

    func testGoalProgress_ExceedingGoal_CapsAtOne() {
        // Given: More time than goal
        sut.todayGoalMinutes = 60
        sut.todayStats.totalMinutes = 90

        // When: Getting goal progress
        let progress = sut.goalProgress

        // Then: Progress should be capped at 1.0
        XCTAssertEqual(progress, 1.0)
    }

    // MARK: - Recent Activities Tests

    func testRecentActivities_LimitsToFive() async {
        // Given: More than 5 activities
        let activities = (0..<10).map { i in
            TestData.makeActivity(
                categoryId: testCategory.id,
                childId: testChild.id,
                startTime: Date().addingTimeInterval(TimeInterval(-3600 * (i + 1))),
                endTime: Date().addingTimeInterval(TimeInterval(-3600 * i - 1800))
            )
        }
        mockActivityService.mockActivities = activities

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: Only 5 most recent activities should be shown
        XCTAssertEqual(sut.recentActivities.count, 5)
        // Verify they're the most recent ones (sorted by start time descending)
        for i in 0..<4 {
            XCTAssertGreaterThanOrEqual(
                sut.recentActivities[i].startTime,
                sut.recentActivities[i + 1].startTime
            )
        }
    }

    func testRecentActivities_WithLessThanFive_ShowsAll() async {
        // Given: Only 3 activities
        let activities = (0..<3).map { i in
            TestData.makeActivity(
                categoryId: testCategory.id,
                childId: testChild.id,
                startTime: Date().addingTimeInterval(TimeInterval(-3600 * (i + 1))),
                endTime: Date().addingTimeInterval(TimeInterval(-3600 * i - 1800))
            )
        }
        mockActivityService.mockActivities = activities

        // When: Loading data
        await sut.loadData(for: testChild)

        // Then: All activities should be shown
        XCTAssertEqual(sut.recentActivities.count, 3)
    }

    // MARK: - Action Handler Tests

    func testStartTimerTapped_SetsNavigationState() {
        // Given: Initial state

        // When: Start timer is tapped
        sut.startTimerTapped()

        // Then: Navigation to timer should be triggered
        XCTAssertTrue(sut.shouldNavigateToTimer)
    }

    func testQuickLogTapped_ShowsSheet() {
        // Given: Initial state

        // When: Quick log is tapped
        sut.quickLogTapped()

        // Then: Quick log sheet should be shown
        XCTAssertTrue(sut.showingQuickLog)
    }

    func testResetNavigation_ClearsNavigationState() {
        // Given: Navigation state is set
        sut.shouldNavigateToTimer = true
        sut.showingQuickLog = true

        // When: Resetting navigation
        sut.resetNavigation()

        // Then: Navigation state should be cleared
        XCTAssertFalse(sut.shouldNavigateToTimer)
        XCTAssertFalse(sut.showingQuickLog)
    }
}

// MARK: - Mock Category Service

class MockCategoryService: CategoryServiceProtocol {
    var mockCategories: [Category] = []
    var mockError: Error?

    func fetchCategories(for child: Child) async throws -> [Category] {
        if let error = mockError {
            throw error
        }
        return mockCategories
    }

    func fetchActiveCategories(for child: Child) async throws -> [Category] {
        if let error = mockError {
            throw error
        }
        return mockCategories.filter { $0.isActive }
    }

    func createCategory(_ category: Category) async throws -> Category {
        if let error = mockError {
            throw error
        }
        return category
    }

    func updateCategory(_ category: Category) async throws -> Category {
        if let error = mockError {
            throw error
        }
        return category
    }

    func deleteCategory(_ categoryId: UUID) async throws {
        if let error = mockError {
            throw error
        }
    }

    func reorderCategories(_ categoryIds: [UUID]) async throws {
        if let error = mockError {
            throw error
        }
    }

    func createDefaultCategories(for child: Child) async throws -> [Category] {
        if let error = mockError {
            throw error
        }
        return []
    }
}
