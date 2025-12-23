//
//  StatisticsViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for StatisticsViewModel functionality
@MainActor
final class StatisticsViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: StatisticsViewModel!
    var mockActivityService: MockActivityService!
    var mockCategoryService: MockCategoryService!
    var testChild: Child!
    var testCategories: [Category]!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockActivityService = MockActivityService()
        mockCategoryService = MockCategoryService()
        testChild = TestData.makeChild()
        testCategories = Category.defaultCategories(for: testChild.id)

        mockCategoryService.mockCategories = testCategories

        sut = StatisticsViewModel(
            activityService: mockActivityService,
            categoryService: mockCategoryService,
            child: testChild
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockActivityService = nil
        mockCategoryService = nil
        testChild = nil
        testCategories = nil
        try await super.tearDown()
    }

    // MARK: - Time Period Filtering Tests

    func testInitialTimePeriodIsToday() {
        XCTAssertEqual(sut.selectedTimePeriod, .today)
    }

    func testChangingTimePeriodUpdatesData() async {
        // Given: Activities for different days
        let calendar = Calendar.current
        let today = Date()

        // Create activity today
        let activityToday = TestData.makeActivity(
            categoryId: testCategories[0].id,
            childId: testChild.id,
            startTime: today.addingTimeInterval(-1800),
            endTime: today
        )

        // Create activity 3 days ago
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let activityOld = TestData.makeActivity(
            categoryId: testCategories[1].id,
            childId: testChild.id,
            startTime: threeDaysAgo.addingTimeInterval(-1800),
            endTime: threeDaysAgo
        )

        mockActivityService.mockActivities = [activityToday, activityOld]

        // When: Load data for today
        await sut.loadData()

        // Then: Only today's activities should be included
        XCTAssertEqual(sut.dailyData.totalMinutes, 30) // 1800 seconds = 30 minutes

        // When: Change to week view
        sut.selectedTimePeriod = .week
        await sut.loadData()

        // Then: Both activities should be included
        XCTAssertEqual(sut.weeklyData.totalMinutes, 60) // Both activities
    }

    func testMonthTimePeriodFiltersCorrectly() async {
        // Given: Activities from different months
        let calendar = Calendar.current
        let today = Date()

        let activityThisMonth = TestData.makeActivity(
            categoryId: testCategories[0].id,
            childId: testChild.id,
            startTime: today.addingTimeInterval(-3600),
            endTime: today
        )

        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        let activityLastMonth = TestData.makeActivity(
            categoryId: testCategories[1].id,
            childId: testChild.id,
            startTime: lastMonth.addingTimeInterval(-3600),
            endTime: lastMonth
        )

        mockActivityService.mockActivities = [activityThisMonth, activityLastMonth]

        // When: Load data for current month
        sut.selectedTimePeriod = .month
        await sut.loadData()

        // Then: Only this month's activities should be included
        XCTAssertEqual(sut.dailyData.totalMinutes, 60) // Only this month
    }

    // MARK: - Category Aggregate Tests

    func testCalculateCategoryAggregatesGroupsByCategory() async {
        // Given: Multiple activities in different categories
        let homework = testCategories.first { $0.name == "Homework" }!
        let reading = testCategories.first { $0.name == "Reading" }!

        let activity1 = TestData.makeActivity(
            categoryId: homework.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600), // 1 hour
            endTime: Date()
        )

        let activity2 = TestData.makeActivity(
            categoryId: homework.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-1800), // 30 min
            endTime: Date()
        )

        let activity3 = TestData.makeActivity(
            categoryId: reading.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-2700), // 45 min
            endTime: Date()
        )

        mockActivityService.mockActivities = [activity1, activity2, activity3]

        // When: Load data
        await sut.loadData()

        // Then: Category breakdown should aggregate correctly
        let homeworkItem = sut.dailyData.categoryBreakdown.first { $0.categoryName == "Homework" }
        let readingItem = sut.dailyData.categoryBreakdown.first { $0.categoryName == "Reading" }

        XCTAssertNotNil(homeworkItem)
        XCTAssertNotNil(readingItem)
        XCTAssertEqual(homeworkItem?.minutes, 90) // 60 + 30
        XCTAssertEqual(readingItem?.minutes, 45)
    }

    func testCategoryBreakdownCalculatesPercentages() async {
        // Given: Activities totaling 100 minutes
        let homework = testCategories.first { $0.name == "Homework" }!
        let reading = testCategories.first { $0.name == "Reading" }!

        let activity1 = TestData.makeActivity(
            categoryId: homework.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600), // 60 min
            endTime: Date()
        )

        let activity2 = TestData.makeActivity(
            categoryId: reading.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-2400), // 40 min
            endTime: Date()
        )

        mockActivityService.mockActivities = [activity1, activity2]

        // When: Load data
        await sut.loadData()

        // Then: Percentages should be calculated correctly
        let homeworkItem = sut.dailyData.categoryBreakdown.first { $0.categoryName == "Homework" }
        let readingItem = sut.dailyData.categoryBreakdown.first { $0.categoryName == "Reading" }

        XCTAssertEqual(homeworkItem?.percentage, 60) // 60/100
        XCTAssertEqual(readingItem?.percentage, 40) // 40/100
    }

    // MARK: - Daily Average Tests

    func testWeeklyAverageCalculation() async {
        // Given: Activities across 7 days totaling 210 minutes
        let calendar = Calendar.current
        let today = Date()

        var activities: [Activity] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let activity = TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-1800), // 30 min each day
                endTime: date
            )
            activities.append(activity)
        }

        mockActivityService.mockActivities = activities

        // When: Load weekly data
        sut.selectedTimePeriod = .week
        await sut.loadData()

        // Then: Average should be 30 minutes per day
        XCTAssertEqual(sut.weeklyData.averageMinutesPerDay, 30)
        XCTAssertEqual(sut.weeklyData.totalMinutes, 210)
    }

    func testMonthlyAverageCalculation() async {
        // Given: Activities across 30 days
        let calendar = Calendar.current
        let today = Date()

        var activities: [Activity] = []
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let activity = TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-3600), // 60 min each day
                endTime: date
            )
            activities.append(activity)
        }

        mockActivityService.mockActivities = activities

        // When: Load monthly data
        sut.selectedTimePeriod = .month
        await sut.loadData()

        // Then: Average should be 60 minutes per day
        XCTAssertEqual(sut.weeklyData.averageMinutesPerDay, 60)
        XCTAssertEqual(sut.weeklyData.totalMinutes, 1800) // 30 * 60
    }

    // MARK: - Streak Tracking Tests

    func testStreakCalculationForConsecutiveDays() async {
        // Given: Activities for the last 5 consecutive days
        let calendar = Calendar.current
        let today = Date()

        var activities: [Activity] = []
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let activity = TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-1800),
                endTime: date
            )
            activities.append(activity)
        }

        mockActivityService.mockActivities = activities

        // When: Load data
        await sut.loadData()

        // Then: Current streak should be 5
        XCTAssertEqual(sut.weeklyData.currentStreak, 5)
    }

    func testStreakBreaksWithMissingDay() async {
        // Given: Activities today and 2 days ago (missing yesterday)
        let calendar = Calendar.current
        let today = Date()

        let activityToday = TestData.makeActivity(
            categoryId: testCategories[0].id,
            childId: testChild.id,
            startTime: today.addingTimeInterval(-1800),
            endTime: today
        )

        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let activityOld = TestData.makeActivity(
            categoryId: testCategories[0].id,
            childId: testChild.id,
            startTime: twoDaysAgo.addingTimeInterval(-1800),
            endTime: twoDaysAgo
        )

        mockActivityService.mockActivities = [activityToday, activityOld]

        // When: Load data
        await sut.loadData()

        // Then: Current streak should be 1 (only today)
        XCTAssertEqual(sut.weeklyData.currentStreak, 1)
    }

    func testLongestStreakTracking() async {
        // Given: Activities for days 0-3 and days 6-9 (two separate streaks)
        let calendar = Calendar.current
        let today = Date()

        var activities: [Activity] = []

        // Recent streak: 4 days (0-3)
        for i in 0..<4 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            activities.append(TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-1800),
                endTime: date
            ))
        }

        // Older streak: 4 days (6-9), but with a gap
        for i in 6..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            activities.append(TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-1800),
                endTime: date
            ))
        }

        mockActivityService.mockActivities = activities

        // When: Load data
        await sut.loadData()

        // Then: Current streak is 4, longest is also 4
        XCTAssertEqual(sut.weeklyData.currentStreak, 4)
        XCTAssertEqual(sut.weeklyData.longestStreak, 4)
    }

    func testZeroStreakWhenNoActivities() async {
        // Given: No activities
        mockActivityService.mockActivities = []

        // When: Load data
        await sut.loadData()

        // Then: Streaks should be 0
        XCTAssertEqual(sut.weeklyData.currentStreak, 0)
        XCTAssertEqual(sut.weeklyData.longestStreak, 0)
    }

    // MARK: - Balance Score Tests

    func testBalanceScoreWithPerfectBalance() async {
        // Given: Equal time in productive and non-productive categories
        let homework = testCategories.first { $0.name == "Homework" }!
        let screenTime = testCategories.first { $0.name == "Screen Time" }!

        let productiveActivity = TestData.makeActivity(
            categoryId: homework.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600), // 60 min
            endTime: Date()
        )

        let screenActivity = TestData.makeActivity(
            categoryId: screenTime.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600), // 60 min
            endTime: Date()
        )

        mockActivityService.mockActivities = [productiveActivity, screenActivity]

        // When: Load data
        await sut.loadData()

        // Then: Balance score should be high (80-100)
        XCTAssertGreaterThanOrEqual(sut.dailyData.balanceScore, 80)
    }

    func testBalanceScoreWithTooMuchScreenTime() async {
        // Given: Much more screen time than productive activities
        let homework = testCategories.first { $0.name == "Homework" }!
        let screenTime = testCategories.first { $0.name == "Screen Time" }!

        let productiveActivity = TestData.makeActivity(
            categoryId: homework.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-1800), // 30 min
            endTime: Date()
        )

        let screenActivity = TestData.makeActivity(
            categoryId: screenTime.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-10800), // 180 min
            endTime: Date()
        )

        mockActivityService.mockActivities = [productiveActivity, screenActivity]

        // When: Load data
        await sut.loadData()

        // Then: Balance score should be low (< 50)
        XCTAssertLessThan(sut.dailyData.balanceScore, 50)
    }

    func testBalanceScoreWithOnlyProductiveActivities() async {
        // Given: Only productive activities
        let homework = testCategories.first { $0.name == "Homework" }!
        let reading = testCategories.first { $0.name == "Reading" }!

        let activity1 = TestData.makeActivity(
            categoryId: homework.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date()
        )

        let activity2 = TestData.makeActivity(
            categoryId: reading.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date()
        )

        mockActivityService.mockActivities = [activity1, activity2]

        // When: Load data
        await sut.loadData()

        // Then: Balance score should be perfect (100)
        XCTAssertEqual(sut.dailyData.balanceScore, 100)
    }

    // MARK: - Error Handling Tests

    func testLoadDataHandlesServiceError() async {
        // Given: Service that throws an error
        mockActivityService.mockError = NSError(domain: "test", code: 1)

        // When: Load data
        await sut.loadData()

        // Then: Error message should be set
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadDataResetsErrorOnSuccess() async {
        // Given: Previous error state
        sut.errorMessage = "Previous error"
        mockActivityService.mockActivities = []

        // When: Load data successfully
        await sut.loadData()

        // Then: Error should be cleared
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Daily Breakdown Tests

    func testDailyBreakdownForWeek() async {
        // Given: Activities for each day of the week
        let calendar = Calendar.current
        let today = Date()

        var activities: [Activity] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let activity = TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-1800),
                endTime: date
            )
            activities.append(activity)
        }

        mockActivityService.mockActivities = activities

        // When: Load weekly data
        sut.selectedTimePeriod = .week
        await sut.loadData()

        // Then: Daily breakdown should have 7 entries
        XCTAssertEqual(sut.weeklyData.dailyBreakdown.count, 7)

        // And each day should have data
        for dayData in sut.weeklyData.dailyBreakdown {
            XCTAssertGreaterThan(dayData.minutes, 0)
            XCTAssertFalse(dayData.dayLabel.isEmpty)
        }
    }

    func testDailyBreakdownSortedChronologically() async {
        // Given: Activities for the week
        let calendar = Calendar.current
        let today = Date()

        var activities: [Activity] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            activities.append(TestData.makeActivity(
                categoryId: testCategories[0].id,
                childId: testChild.id,
                startTime: date.addingTimeInterval(-1800),
                endTime: date
            ))
        }

        mockActivityService.mockActivities = activities

        // When: Load weekly data
        sut.selectedTimePeriod = .week
        await sut.loadData()

        // Then: Daily breakdown should be sorted from oldest to newest
        let dates = sut.weeklyData.dailyBreakdown.map { $0.date }
        let sortedDates = dates.sorted()
        XCTAssertEqual(dates, sortedDates)
    }
}

// MARK: - Mock CategoryService

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
        mockCategories.append(category)
        return category
    }

    func updateCategory(_ category: Category) async throws -> Category {
        if let error = mockError {
            throw error
        }
        if let index = mockCategories.firstIndex(where: { $0.id == category.id }) {
            mockCategories[index] = category
        }
        return category
    }

    func deleteCategory(_ categoryId: UUID) async throws {
        if let error = mockError {
            throw error
        }
        mockCategories.removeAll { $0.id == categoryId }
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
        let defaults = Category.defaultCategories(for: child.id)
        mockCategories.append(contentsOf: defaults)
        return defaults
    }
}
