//
//  ActivityLogViewModelTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import Combine
@testable import FocusPal

/// Comprehensive tests for ActivityLogViewModel
/// Tests cover initialization, activity loading, logging, manual entry, and deletion
@MainActor
final class ActivityLogViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: ActivityLogViewModel!
    var mockActivityService: MockActivityService!
    var mockCategoryService: MockCategoryService!
    var cancellables: Set<AnyCancellable>!

    // Test data
    var testChild: Child!
    var testCategory1: Category!
    var testCategory2: Category!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create test data
        testChild = TestData.makeChild(name: "Test Child", age: 8)
        testCategory1 = TestData.makeCategory(
            name: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            childId: testChild.id
        )
        testCategory2 = TestData.makeCategory(
            name: "Reading",
            iconName: "text.book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )

        // Create mock services
        mockActivityService = MockActivityService()
        mockCategoryService = MockCategoryService()
        mockCategoryService.mockCategories = [testCategory1, testCategory2]

        // Create view model with mock services
        viewModel = ActivityLogViewModel(
            activityService: mockActivityService,
            categoryService: mockCategoryService
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        viewModel = nil
        mockActivityService = nil
        mockCategoryService = nil
        cancellables = nil
        testChild = nil
        testCategory1 = nil
        testCategory2 = nil

        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_SetsDefaultValues() {
        // Assert
        XCTAssertTrue(viewModel.activities.isEmpty)
        XCTAssertFalse(viewModel.categories.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)

        // Verify selected date is today
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInToday(viewModel.selectedDate))
    }

    func testInitialization_LoadsCategories() async {
        // Assert
        XCTAssertEqual(viewModel.categories.count, 2)
        XCTAssertEqual(viewModel.categories[0].name, "Homework")
        XCTAssertEqual(viewModel.categories[1].name, "Reading")
    }

    // MARK: - Load Activities Tests

    func testLoadActivities_WithEmptyDate_ReturnsEmptyList() async {
        // Act
        await viewModel.loadActivities()

        // Assert
        XCTAssertTrue(viewModel.activities.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadActivities_WithActivities_PopulatesActivitiesList() async {
        // Arrange
        let activity1 = TestData.makeActivity(
            categoryId: testCategory1.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(-1800)
        )
        let activity2 = TestData.makeActivity(
            categoryId: testCategory2.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date()
        )
        mockActivityService.mockActivities = [activity1, activity2]

        // Act
        await viewModel.loadActivities()

        // Assert
        XCTAssertEqual(viewModel.activities.count, 2)
        XCTAssertEqual(viewModel.activities[0].categoryName, "Homework")
        XCTAssertEqual(viewModel.activities[1].categoryName, "Reading")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadActivities_SetsLoadingStateCorrectly() async {
        // Arrange
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        await viewModel.loadActivities()

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(loadingStates.contains(true), "Should set loading to true")
        XCTAssertFalse(viewModel.isLoading, "Should reset loading to false")
    }

    func testLoadActivities_WithError_SetsErrorMessage() async {
        // Arrange
        mockActivityService.mockError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // Act
        await viewModel.loadActivities()

        // Assert
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Test error")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadActivities_FiltersBySelectedDate() async {
        // Arrange
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStart = calendar.startOfDay(for: yesterday)

        let todayActivity = TestData.makeActivity(
            categoryId: testCategory1.id,
            childId: testChild.id,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date()
        )
        let yesterdayActivity = TestData.makeActivity(
            categoryId: testCategory2.id,
            childId: testChild.id,
            startTime: yesterdayStart.addingTimeInterval(3600),
            endTime: yesterdayStart.addingTimeInterval(7200)
        )
        mockActivityService.mockActivities = [todayActivity, yesterdayActivity]

        // Act - Load today's activities
        await viewModel.loadActivities()
        let todayCount = viewModel.activities.count

        // Change to yesterday
        viewModel.selectedDate = yesterday
        await viewModel.loadActivities()
        let yesterdayCount = viewModel.activities.count

        // Assert
        XCTAssertEqual(todayCount, 1, "Should only show today's activities")
        XCTAssertEqual(yesterdayCount, 1, "Should only show yesterday's activities")
    }

    // MARK: - Log Activity Tests (Quick Log)

    func testLogActivity_CreatesNewActivity() async {
        // Arrange
        let duration: TimeInterval = 30 * 60 // 30 minutes

        // Act
        await viewModel.logActivity(category: testCategory1, duration: duration)

        // Assert
        XCTAssertEqual(mockActivityService.logActivityCallCount, 1)
        XCTAssertEqual(mockActivityService.mockActivities.count, 1)

        let loggedActivity = mockActivityService.mockActivities.first!
        XCTAssertEqual(loggedActivity.categoryId, testCategory1.id)
        XCTAssertEqual(loggedActivity.durationMinutes, 30)
        XCTAssertFalse(loggedActivity.isManualEntry)
    }

    func testLogActivity_ReloadsActivitiesList() async {
        // Arrange
        let duration: TimeInterval = 15 * 60

        // Act
        await viewModel.logActivity(category: testCategory1, duration: duration)

        // Assert
        XCTAssertEqual(viewModel.activities.count, 1)
        XCTAssertEqual(viewModel.activities[0].durationMinutes, 15)
    }

    func testLogActivity_WithError_SetsErrorMessage() async {
        // Arrange
        mockActivityService.mockError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Log failed"])

        // Act
        await viewModel.logActivity(category: testCategory1, duration: 1800)

        // Assert
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Log failed")
    }

    // MARK: - Manual Entry Tests

    func testLogManualActivity_CreatesActivityWithCustomStartTime() async {
        // Arrange
        let startTime = Date().addingTimeInterval(-7200) // 2 hours ago
        let duration: TimeInterval = 45 * 60 // 45 minutes
        let notes = "Completed math homework"
        let mood = Mood.happy

        // Act
        await viewModel.logManualActivity(
            category: testCategory1,
            startTime: startTime,
            duration: duration,
            notes: notes,
            mood: mood
        )

        // Assert
        XCTAssertEqual(mockActivityService.mockActivities.count, 1)

        let activity = mockActivityService.mockActivities.first!
        XCTAssertEqual(activity.categoryId, testCategory1.id)
        XCTAssertEqual(activity.notes, notes)
        XCTAssertEqual(activity.mood, mood)
        XCTAssertTrue(activity.isManualEntry)

        // Verify start and end times
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(activity.startTime, equalTo: startTime, toGranularity: .minute))
        XCTAssertEqual(Int(activity.duration / 60), 45)
    }

    func testLogManualActivity_WithNilNotes_CreatesActivityWithoutNotes() async {
        // Arrange
        let startTime = Date().addingTimeInterval(-3600)
        let duration: TimeInterval = 20 * 60

        // Act
        await viewModel.logManualActivity(
            category: testCategory2,
            startTime: startTime,
            duration: duration,
            notes: nil,
            mood: .neutral
        )

        // Assert
        XCTAssertEqual(mockActivityService.mockActivities.count, 1)
        let activity = mockActivityService.mockActivities.first!
        XCTAssertNil(activity.notes)
    }

    func testLogManualActivity_WithEmptyNotes_CreatesActivityWithoutNotes() async {
        // Arrange
        let startTime = Date().addingTimeInterval(-3600)
        let duration: TimeInterval = 20 * 60

        // Act
        await viewModel.logManualActivity(
            category: testCategory2,
            startTime: startTime,
            duration: duration,
            notes: "",
            mood: .neutral
        )

        // Assert
        XCTAssertEqual(mockActivityService.mockActivities.count, 1)
        let activity = mockActivityService.mockActivities.first!
        XCTAssertNil(activity.notes)
    }

    func testLogManualActivity_ReloadsActivitiesList() async {
        // Arrange
        let startTime = Date().addingTimeInterval(-3600)
        let duration: TimeInterval = 30 * 60

        // Act
        await viewModel.logManualActivity(
            category: testCategory1,
            startTime: startTime,
            duration: duration,
            notes: "Test notes",
            mood: .happy
        )

        // Assert
        XCTAssertEqual(viewModel.activities.count, 1)
    }

    func testLogManualActivity_WithAllMoodTypes_CreatesActivityWithCorrectMood() async {
        // Test each mood type
        for mood in [Mood.none, .verySad, .sad, .neutral, .happy, .veryHappy] {
            // Arrange
            mockActivityService.reset()
            let startTime = Date().addingTimeInterval(-3600)
            let duration: TimeInterval = 10 * 60

            // Act
            await viewModel.logManualActivity(
                category: testCategory1,
                startTime: startTime,
                duration: duration,
                notes: nil,
                mood: mood
            )

            // Assert
            XCTAssertEqual(mockActivityService.mockActivities.count, 1)
            let activity = mockActivityService.mockActivities.first!
            XCTAssertEqual(activity.mood, mood, "Mood should be \(mood)")
        }
    }

    // MARK: - Delete Activity Tests

    func testDeleteActivities_RemovesActivitiesFromList() async {
        // Arrange
        let activity1 = TestData.makeActivity(
            categoryId: testCategory1.id,
            childId: testChild.id
        )
        let activity2 = TestData.makeActivity(
            categoryId: testCategory2.id,
            childId: testChild.id
        )
        mockActivityService.mockActivities = [activity1, activity2]
        await viewModel.loadActivities()

        XCTAssertEqual(viewModel.activities.count, 2)

        // Act
        let indexSet = IndexSet(integer: 0)
        viewModel.deleteActivities(at: indexSet)

        // Wait for deletion to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Assert
        XCTAssertEqual(mockActivityService.deleteCallCount, 1)
        XCTAssertEqual(mockActivityService.mockActivities.count, 1)
        XCTAssertEqual(viewModel.activities.count, 1)
    }

    func testDeleteActivities_WithMultipleIndices_RemovesAllSpecifiedActivities() async {
        // Arrange
        let activity1 = TestData.makeActivity(categoryId: testCategory1.id, childId: testChild.id)
        let activity2 = TestData.makeActivity(categoryId: testCategory2.id, childId: testChild.id)
        let activity3 = TestData.makeActivity(categoryId: testCategory1.id, childId: testChild.id)
        mockActivityService.mockActivities = [activity1, activity2, activity3]
        await viewModel.loadActivities()

        XCTAssertEqual(viewModel.activities.count, 3)

        // Act
        let indexSet = IndexSet([0, 2])
        viewModel.deleteActivities(at: indexSet)

        // Wait for deletion to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(mockActivityService.deleteCallCount, 2)
        XCTAssertEqual(mockActivityService.mockActivities.count, 1)
        XCTAssertEqual(viewModel.activities.count, 1)
    }

    func testDeleteActivities_WithError_ContinuesWithOtherDeletions() async {
        // Arrange
        let activity1 = TestData.makeActivity(categoryId: testCategory1.id, childId: testChild.id)
        let activity2 = TestData.makeActivity(categoryId: testCategory2.id, childId: testChild.id)
        mockActivityService.mockActivities = [activity1, activity2]
        await viewModel.loadActivities()

        // Set error after first deletion
        mockActivityService.mockError = NSError(domain: "Test", code: 1, userInfo: [:])

        // Act
        let indexSet = IndexSet([0, 1])
        viewModel.deleteActivities(at: indexSet)

        // Wait for deletion to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert - deletion should attempt all indices despite errors
        XCTAssertEqual(mockActivityService.deleteCallCount, 2)
    }

    // MARK: - Activity Display Item Mapping Tests

    func testActivityMapping_CreatesDisplayItemsWithCorrectData() async {
        // Arrange
        let startTime = Date().addingTimeInterval(-3600)
        let endTime = Date().addingTimeInterval(-1800)
        let activity = TestData.makeActivity(
            categoryId: testCategory1.id,
            childId: testChild.id,
            startTime: startTime,
            endTime: endTime
        )
        mockActivityService.mockActivities = [activity]

        // Act
        await viewModel.loadActivities()

        // Assert
        XCTAssertEqual(viewModel.activities.count, 1)
        let displayItem = viewModel.activities[0]

        XCTAssertEqual(displayItem.id, activity.id)
        XCTAssertEqual(displayItem.categoryName, "Homework")
        XCTAssertEqual(displayItem.iconName, "book.fill")
        XCTAssertEqual(displayItem.colorHex, "#4A90D9")
        XCTAssertEqual(displayItem.durationMinutes, 30)
        XCTAssertFalse(displayItem.timeRange.isEmpty)
    }

    func testActivityMapping_WithUnknownCategory_ShowsUnknown() async {
        // Arrange
        let unknownCategoryId = UUID()
        let activity = TestData.makeActivity(
            categoryId: unknownCategoryId,
            childId: testChild.id
        )
        mockActivityService.mockActivities = [activity]

        // Act
        await viewModel.loadActivities()

        // Assert
        XCTAssertEqual(viewModel.activities.count, 1)
        let displayItem = viewModel.activities[0]

        XCTAssertEqual(displayItem.categoryName, "Unknown")
        XCTAssertEqual(displayItem.iconName, "circle.fill")
        XCTAssertEqual(displayItem.colorHex, "#888888")
    }

    // MARK: - Date Change Tests

    func testDateChange_TriggersActivityReload() async {
        // Arrange
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        // Add activity for tomorrow
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        let activity = TestData.makeActivity(
            categoryId: testCategory1.id,
            childId: testChild.id,
            startTime: tomorrowStart.addingTimeInterval(3600),
            endTime: tomorrowStart.addingTimeInterval(5400)
        )
        mockActivityService.mockActivities = [activity]

        // Act
        await viewModel.loadActivities()
        XCTAssertEqual(viewModel.activities.count, 0, "Today should have no activities")

        viewModel.selectedDate = tomorrow
        await viewModel.loadActivities()

        // Assert
        XCTAssertEqual(viewModel.activities.count, 1, "Tomorrow should have one activity")
    }
}

// MARK: - Mock Category Service

class MockCategoryService: CategoryServiceProtocol {
    var mockCategories: [Category] = []
    var mockError: Error?

    func fetchCategories(for child: Child) async throws -> [Category] {
        if let error = mockError { throw error }
        return mockCategories
    }

    func fetchActiveCategories(for child: Child) async throws -> [Category] {
        if let error = mockError { throw error }
        return mockCategories.filter { $0.isActive }
    }

    func createCategory(_ category: Category) async throws -> Category {
        if let error = mockError { throw error }
        mockCategories.append(category)
        return category
    }

    func updateCategory(_ category: Category) async throws -> Category {
        if let error = mockError { throw error }
        if let index = mockCategories.firstIndex(where: { $0.id == category.id }) {
            mockCategories[index] = category
        }
        return category
    }

    func deleteCategory(_ categoryId: UUID) async throws {
        if let error = mockError { throw error }
        mockCategories.removeAll { $0.id == categoryId }
    }

    func reorderCategories(_ categoryIds: [UUID]) async throws {
        if let error = mockError { throw error }
    }

    func createDefaultCategories(for child: Child) async throws -> [Category] {
        if let error = mockError { throw error }
        let defaults = Category.defaultCategories(for: child.id)
        mockCategories.append(contentsOf: defaults)
        return defaults
    }
}
