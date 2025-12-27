//
//  CoreDataTimeGoalRepositoryTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import CoreData
@testable import FocusPal

// Type alias to disambiguate from Swift Charts' Category
typealias TestCategory = FocusPal.Category

/// Comprehensive tests for CoreDataTimeGoalRepository
/// Tests all CRUD operations and specialized queries
final class CoreDataTimeGoalRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataTimeGoalRepository!
    var testContext: NSManagedObjectContext!
    var testChild: Child!
    var testCategory: TestCategory!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Setup test CoreData stack
        let testStack = TestCoreDataStack.shared
        testStack.clearAllData()
        testContext = testStack.newTestContext()

        // Initialize repository with test context
        sut = CoreDataTimeGoalRepository(context: testContext)

        // Create test child and category
        testChild = Child(name: "Test Child", age: 10)
        try createChildEntity(testChild)

        testCategory = TestCategory(
            name: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            childId: testChild.id
        )
        try createCategoryEntity(testCategory)
    }

    override func tearDownWithError() throws {
        sut = nil
        testContext = nil
        testChild = nil
        testCategory = nil
        TestCoreDataStack.shared.clearAllData()
        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithValidTimeGoal_SavesSuccessfully() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80
        )

        // Act
        let created = try await sut.create(timeGoal)

        // Assert
        XCTAssertEqual(created.id, timeGoal.id, "Created time goal should have same ID")
        XCTAssertEqual(created.categoryId, timeGoal.categoryId)
        XCTAssertEqual(created.childId, timeGoal.childId)
        XCTAssertEqual(created.recommendedMinutes, 60)
        XCTAssertEqual(created.warningThreshold, 80)
        XCTAssertTrue(created.isActive)
    }

    func testCreate_WithInactiveGoal_SavesCorrectly() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 90,
            warningThreshold: 75,
            isActive: false
        )

        // Act
        let created = try await sut.create(timeGoal)

        // Assert
        XCTAssertFalse(created.isActive, "Should save inactive status")
        XCTAssertEqual(created.recommendedMinutes, 90)
        XCTAssertEqual(created.warningThreshold, 75)
    }

    func testCreate_WithCustomCreatedDate_SavesCorrectly() async throws {
        // Arrange
        let customDate = Date().addingTimeInterval(-86400) // Yesterday
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 45,
            createdDate: customDate
        )

        // Act
        let created = try await sut.create(timeGoal)

        // Assert
        XCTAssertEqual(created.createdDate.timeIntervalSince1970,
                      customDate.timeIntervalSince1970,
                      accuracy: 1.0,
                      "Should save custom created date")
    }

    func testCreate_MultipleGoals_AllSavedSuccessfully() async throws {
        // Arrange: Create additional categories
        let category2 = TestCategory(
            name: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            childId: testChild.id
        )
        try createCategoryEntity(category2)

        let timeGoal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        let timeGoal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 120
        )

        // Act
        let created1 = try await sut.create(timeGoal1)
        let created2 = try await sut.create(timeGoal2)

        // Assert
        XCTAssertNotEqual(created1.id, created2.id)
        XCTAssertNotEqual(created1.categoryId, created2.categoryId)
        XCTAssertEqual(created1.recommendedMinutes, 60)
        XCTAssertEqual(created2.recommendedMinutes, 120)
    }

    // MARK: - FetchAll Tests

    func testFetchAll_WithNoTimeGoals_ReturnsEmptyArray() async throws {
        // Act
        let timeGoals = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertTrue(timeGoals.isEmpty, "Should return empty array when no time goals exist")
    }

    func testFetchAll_WithMultipleTimeGoals_ReturnsAllForChild() async throws {
        // Arrange: Create additional categories and goals
        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        let category3 = TestCategory(
            name: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            childId: testChild.id
        )
        try createCategoryEntity(category2)
        try createCategoryEntity(category3)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        let goal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90
        )
        let goal3 = TimeGoal(
            categoryId: category3.id,
            childId: testChild.id,
            recommendedMinutes: 120
        )

        _ = try await sut.create(goal1)
        _ = try await sut.create(goal2)
        _ = try await sut.create(goal3)

        // Act
        let timeGoals = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(timeGoals.count, 3, "Should return all time goals for child")
        let categoryIds = Set(timeGoals.map { $0.categoryId })
        XCTAssertTrue(categoryIds.contains(testCategory.id))
        XCTAssertTrue(categoryIds.contains(category2.id))
        XCTAssertTrue(categoryIds.contains(category3.id))
    }

    func testFetchAll_OnlyReturnsGoalsForSpecificChild() async throws {
        // Arrange: Create another child and goal
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let otherCategory = TestCategory(
            name: "Music",
            iconName: "music.note",
            colorHex: "#F7DC6F",
            childId: otherChild.id
        )
        try createCategoryEntity(otherCategory)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        let goal2 = TimeGoal(
            categoryId: otherCategory.id,
            childId: otherChild.id,
            recommendedMinutes: 90
        )

        _ = try await sut.create(goal1)
        _ = try await sut.create(goal2)

        // Act
        let timeGoals = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(timeGoals.count, 1, "Should only return time goals for specific child")
        XCTAssertEqual(timeGoals[0].childId, testChild.id)
    }

    func testFetchAll_SortsByCreatedDateDescending() async throws {
        // Arrange: Create goals at different times
        let oldDate = Date().addingTimeInterval(-172800) // 2 days ago
        let middleDate = Date().addingTimeInterval(-86400) // Yesterday
        let recentDate = Date() // Today

        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        let category3 = TestCategory(
            name: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            childId: testChild.id
        )
        try createCategoryEntity(category2)
        try createCategoryEntity(category3)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            createdDate: middleDate
        )
        let goal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90,
            createdDate: recentDate
        )
        let goal3 = TimeGoal(
            categoryId: category3.id,
            childId: testChild.id,
            recommendedMinutes: 120,
            createdDate: oldDate
        )

        _ = try await sut.create(goal1)
        _ = try await sut.create(goal2)
        _ = try await sut.create(goal3)

        // Act
        let timeGoals = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(timeGoals.count, 3)
        // Should be sorted by created date descending (most recent first)
        XCTAssertEqual(timeGoals[0].categoryId, category2.id) // Recent
        XCTAssertEqual(timeGoals[1].categoryId, testCategory.id) // Middle
        XCTAssertEqual(timeGoals[2].categoryId, category3.id) // Old
    }

    // MARK: - Fetch by ChildId and CategoryId Tests

    func testFetch_WithValidChildAndCategory_ReturnsTimeGoal() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 85
        )
        _ = try await sut.create(timeGoal)

        // Act
        let fetched = try await sut.fetch(
            for: testChild.id,
            categoryId: testCategory.id
        )

        // Assert
        XCTAssertNotNil(fetched, "Should find time goal")
        XCTAssertEqual(fetched?.id, timeGoal.id)
        XCTAssertEqual(fetched?.categoryId, testCategory.id)
        XCTAssertEqual(fetched?.childId, testChild.id)
        XCTAssertEqual(fetched?.recommendedMinutes, 60)
        XCTAssertEqual(fetched?.warningThreshold, 85)
    }

    func testFetch_WithNonExistentCategory_ReturnsNil() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        _ = try await sut.create(timeGoal)

        // Act
        let wrongCategoryId = UUID()
        let fetched = try await sut.fetch(
            for: testChild.id,
            categoryId: wrongCategoryId
        )

        // Assert
        XCTAssertNil(fetched, "Should return nil for non-existent category")
    }

    func testFetch_WithWrongChildId_ReturnsNil() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        _ = try await sut.create(timeGoal)

        // Act
        let wrongChildId = UUID()
        let fetched = try await sut.fetch(
            for: wrongChildId,
            categoryId: testCategory.id
        )

        // Assert
        XCTAssertNil(fetched, "Should return nil for wrong child ID")
    }

    func testFetch_OneGoalPerChildCategoryPair() async throws {
        // Verify only one goal can exist per child-category combination
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        _ = try await sut.create(timeGoal)

        // Act
        let fetched = try await sut.fetch(
            for: testChild.id,
            categoryId: testCategory.id
        )

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.categoryId, testCategory.id)
    }

    // MARK: - Fetch by ID Tests

    func testFetch_ById_WithValidId_ReturnsTimeGoal() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 75,
            warningThreshold: 90
        )
        let created = try await sut.create(timeGoal)

        // Act
        let fetched = try await sut.fetch(by: created.id)

        // Assert
        XCTAssertNotNil(fetched, "Should find time goal by ID")
        XCTAssertEqual(fetched?.id, created.id)
        XCTAssertEqual(fetched?.recommendedMinutes, 75)
        XCTAssertEqual(fetched?.warningThreshold, 90)
    }

    func testFetch_ById_WithNonExistentId_ReturnsNil() async throws {
        // Arrange
        let nonExistentId = UUID()

        // Act
        let fetched = try await sut.fetch(by: nonExistentId)

        // Assert
        XCTAssertNil(fetched, "Should return nil for non-existent ID")
    }

    func testFetch_ById_WithMultipleGoals_ReturnsCorrectOne() async throws {
        // Arrange: Create multiple goals
        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        try createCategoryEntity(category2)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        let goal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90
        )

        let created1 = try await sut.create(goal1)
        let created2 = try await sut.create(goal2)

        // Act
        let fetched1 = try await sut.fetch(by: created1.id)
        let fetched2 = try await sut.fetch(by: created2.id)

        // Assert
        XCTAssertEqual(fetched1?.id, created1.id)
        XCTAssertEqual(fetched1?.recommendedMinutes, 60)
        XCTAssertEqual(fetched2?.id, created2.id)
        XCTAssertEqual(fetched2?.recommendedMinutes, 90)
    }

    // MARK: - Update Tests

    func testUpdate_WithExistingGoal_UpdatesSuccessfully() async throws {
        // Arrange: Create initial goal
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80
        )
        let created = try await sut.create(timeGoal)

        // Act: Update recommended minutes
        var updated = created
        updated.recommendedMinutes = 90
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.recommendedMinutes, 90)
        XCTAssertEqual(result.warningThreshold, 80)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertEqual(fetched?.recommendedMinutes, 90)
    }

    func testUpdate_ChangesWarningThreshold_SavesCorrectly() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80
        )
        let created = try await sut.create(timeGoal)

        // Act: Update warning threshold
        var updated = created
        updated.warningThreshold = 90
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.warningThreshold, 90)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertEqual(fetched?.warningThreshold, 90)
    }

    func testUpdate_DeactivatesGoal_SavesCorrectly() async throws {
        // Arrange: Create active goal
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: true
        )
        let created = try await sut.create(timeGoal)
        XCTAssertTrue(created.isActive)

        // Act: Deactivate goal
        var updated = created
        updated.isActive = false
        let result = try await sut.update(updated)

        // Assert
        XCTAssertFalse(result.isActive)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertFalse(fetched!.isActive)
    }

    func testUpdate_ReactivatesGoal_SavesCorrectly() async throws {
        // Arrange: Create inactive goal
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: false
        )
        let created = try await sut.create(timeGoal)

        // Act: Reactivate goal
        var updated = created
        updated.isActive = true
        let result = try await sut.update(updated)

        // Assert
        XCTAssertTrue(result.isActive)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertTrue(fetched!.isActive)
    }

    func testUpdate_WithNonExistentId_ThrowsError() async throws {
        // Arrange: Create goal with ID that doesn't exist
        let timeGoal = TimeGoal(
            id: UUID(),  // Non-existent ID
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )

        // Act & Assert
        do {
            _ = try await sut.update(timeGoal)
            XCTFail("Should throw error for non-existent time goal")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    func testUpdate_MultipleFields_AllChangePersist() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80,
            isActive: true
        )
        let created = try await sut.create(timeGoal)

        // Act: Update all mutable fields
        var updated = created
        updated.recommendedMinutes = 120
        updated.warningThreshold = 75
        updated.isActive = false
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.recommendedMinutes, 120)
        XCTAssertEqual(result.warningThreshold, 75)
        XCTAssertFalse(result.isActive)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertEqual(fetched?.recommendedMinutes, 120)
        XCTAssertEqual(fetched?.warningThreshold, 75)
        XCTAssertFalse(fetched!.isActive)
    }

    // MARK: - Delete Tests

    func testDelete_WithExistingId_DeletesSuccessfully() async throws {
        // Arrange
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        let created = try await sut.create(timeGoal)

        // Verify it exists
        let beforeDelete = try await sut.fetch(by: created.id)
        XCTAssertNotNil(beforeDelete)

        // Act
        try await sut.delete(created.id)

        // Assert
        let afterDelete = try await sut.fetch(by: created.id)
        XCTAssertNil(afterDelete, "Time goal should be deleted")
    }

    func testDelete_WithNonExistentId_ThrowsError() async throws {
        // Arrange
        let nonExistentId = UUID()

        // Act & Assert
        do {
            try await sut.delete(nonExistentId)
            XCTFail("Should throw error for non-existent time goal")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    func testDelete_DoesNotAffectOtherGoals() async throws {
        // Arrange: Create multiple goals
        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        try createCategoryEntity(category2)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60
        )
        let goal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90
        )

        let created1 = try await sut.create(goal1)
        let created2 = try await sut.create(goal2)

        // Act: Delete only first goal
        try await sut.delete(created1.id)

        // Assert: Second goal still exists
        let remaining = try await sut.fetchAll(for: testChild.id)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, created2.id)
    }

    // MARK: - FetchActive Tests

    func testFetchActive_WithNoActiveGoals_ReturnsEmptyArray() async throws {
        // Arrange: Create only inactive goals
        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        try createCategoryEntity(category2)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: false
        )
        let goal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90,
            isActive: false
        )

        _ = try await sut.create(goal1)
        _ = try await sut.create(goal2)

        // Act
        let active = try await sut.fetchActive(for: testChild.id)

        // Assert
        XCTAssertTrue(active.isEmpty, "Should return empty array when no goals are active")
    }

    func testFetchActive_WithActiveGoals_ReturnsOnlyActive() async throws {
        // Arrange: Create mix of active and inactive goals
        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        let category3 = TestCategory(
            name: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            childId: testChild.id
        )
        try createCategoryEntity(category2)
        try createCategoryEntity(category3)

        let activeGoal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: true
        )
        let inactiveGoal = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90,
            isActive: false
        )
        let activeGoal2 = TimeGoal(
            categoryId: category3.id,
            childId: testChild.id,
            recommendedMinutes: 120,
            isActive: true
        )

        _ = try await sut.create(activeGoal1)
        _ = try await sut.create(inactiveGoal)
        _ = try await sut.create(activeGoal2)

        // Act
        let activeGoals = try await sut.fetchActive(for: testChild.id)

        // Assert
        XCTAssertEqual(activeGoals.count, 2, "Should return only active goals")
        XCTAssertTrue(activeGoals.allSatisfy { $0.isActive })

        let categoryIds = Set(activeGoals.map { $0.categoryId })
        XCTAssertTrue(categoryIds.contains(testCategory.id))
        XCTAssertTrue(categoryIds.contains(category3.id))
        XCTAssertFalse(categoryIds.contains(category2.id))
    }

    func testFetchActive_SortsByCreatedDateDescending() async throws {
        // Arrange: Create active goals at different times
        let oldDate = Date().addingTimeInterval(-172800) // 2 days ago
        let middleDate = Date().addingTimeInterval(-86400) // Yesterday
        let recentDate = Date() // Today

        let category2 = TestCategory(
            name: "Reading",
            iconName: "book.closed.fill",
            colorHex: "#7B68EE",
            childId: testChild.id
        )
        let category3 = TestCategory(
            name: "Screen Time",
            iconName: "tv.fill",
            colorHex: "#FF6B6B",
            childId: testChild.id
        )
        try createCategoryEntity(category2)
        try createCategoryEntity(category3)

        let goal1 = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: true,
            createdDate: middleDate
        )
        let goal2 = TimeGoal(
            categoryId: category2.id,
            childId: testChild.id,
            recommendedMinutes: 90,
            isActive: true,
            createdDate: recentDate
        )
        let goal3 = TimeGoal(
            categoryId: category3.id,
            childId: testChild.id,
            recommendedMinutes: 120,
            isActive: true,
            createdDate: oldDate
        )

        _ = try await sut.create(goal1)
        _ = try await sut.create(goal2)
        _ = try await sut.create(goal3)

        // Act
        let active = try await sut.fetchActive(for: testChild.id)

        // Assert
        XCTAssertEqual(active.count, 3)
        // Should be sorted by created date descending (most recent first)
        XCTAssertEqual(active[0].categoryId, category2.id) // Recent
        XCTAssertEqual(active[1].categoryId, testCategory.id) // Middle
        XCTAssertEqual(active[2].categoryId, category3.id) // Old
    }

    func testFetchActive_OnlyReturnsForSpecificChild() async throws {
        // Arrange: Create another child with active goal
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let otherCategory = TestCategory(
            name: "Music",
            iconName: "music.note",
            colorHex: "#F7DC6F",
            childId: otherChild.id
        )
        try createCategoryEntity(otherCategory)

        let testChildGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: true
        )
        let otherChildGoal = TimeGoal(
            categoryId: otherCategory.id,
            childId: otherChild.id,
            recommendedMinutes: 90,
            isActive: true
        )

        _ = try await sut.create(testChildGoal)
        _ = try await sut.create(otherChildGoal)

        // Act
        let active = try await sut.fetchActive(for: testChild.id)

        // Assert
        XCTAssertEqual(active.count, 1, "Should only return active goals for specific child")
        XCTAssertEqual(active[0].childId, testChild.id)
    }

    func testFetchActive_AfterDeactivation_NoLongerReturnsGoal() async throws {
        // Arrange: Create active goal
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            isActive: true
        )
        let created = try await sut.create(timeGoal)

        // Verify it's in active list
        var active = try await sut.fetchActive(for: testChild.id)
        XCTAssertEqual(active.count, 1)

        // Act: Deactivate goal
        var updated = created
        updated.isActive = false
        _ = try await sut.update(updated)

        // Assert: No longer in active list
        active = try await sut.fetchActive(for: testChild.id)
        XCTAssertTrue(active.isEmpty, "Deactivated goal should not be in active list")
    }

    // MARK: - Edge Cases & Integration Tests

    func testTimeGoalLifecycle_CreateUpdateActivateDeactivateDelete() async throws {
        // Test complete lifecycle of a time goal

        // 1. Create active goal
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            warningThreshold: 80,
            isActive: true
        )
        let created = try await sut.create(timeGoal)

        // 2. Verify it's in active list
        var active = try await sut.fetchActive(for: testChild.id)
        XCTAssertEqual(active.count, 1)

        // 3. Update recommended minutes
        var current = created
        current.recommendedMinutes = 90
        current = try await sut.update(current)
        XCTAssertEqual(current.recommendedMinutes, 90)

        // 4. Deactivate goal
        current.isActive = false
        current = try await sut.update(current)

        // 5. Verify no longer in active list
        active = try await sut.fetchActive(for: testChild.id)
        XCTAssertTrue(active.isEmpty)

        // 6. Verify still in fetchAll
        let all = try await sut.fetchAll(for: testChild.id)
        XCTAssertEqual(all.count, 1)

        // 7. Reactivate
        current.isActive = true
        current = try await sut.update(current)

        // 8. Verify back in active list
        active = try await sut.fetchActive(for: testChild.id)
        XCTAssertEqual(active.count, 1)

        // 9. Delete goal
        try await sut.delete(current.id)

        // 10. Verify it's gone
        let finalAll = try await sut.fetchAll(for: testChild.id)
        XCTAssertTrue(finalAll.isEmpty)
    }

    func testConcurrentOperations_DoNotCorruptData() async throws {
        // Create multiple categories for concurrent operations
        let categories = try (0..<5).map { i -> TestCategory in
            let category = TestCategory(
                name: "Category \(i)",
                iconName: "star.fill",
                colorHex: "#4A90D9",
                childId: testChild.id
            )
            try createCategoryEntity(category)
            return category
        }

        let timeGoals = categories.map { category in
            TimeGoal(
                categoryId: category.id,
                childId: testChild.id,
                recommendedMinutes: 60 + (Int.random(in: 0..<60)),
                warningThreshold: 80
            )
        }

        // Create all concurrently
        try await withThrowingTaskGroup(of: TimeGoal.self) { group in
            for timeGoal in timeGoals {
                group.addTask {
                    try await self.sut.create(timeGoal)
                }
            }

            for try await _ in group {
                // Wait for all to complete
            }
        }

        // Verify all created
        let all = try await sut.fetchAll(for: testChild.id)
        XCTAssertEqual(all.count, 5, "All concurrent creates should succeed")
    }

    func testWarningCalculations_WorkWithPersistedData() async throws {
        // Test that domain model calculations work with persisted data
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 100,
            warningThreshold: 80
        )

        let created = try await sut.create(timeGoal)

        // Test warning threshold calculation
        XCTAssertTrue(created.shouldWarn(currentMinutes: 80))
        XCTAssertFalse(created.shouldWarn(currentMinutes: 79))

        // Test exceeded check
        XCTAssertTrue(created.isExceeded(currentMinutes: 100))
        XCTAssertFalse(created.isExceeded(currentMinutes: 99))

        // Test progress percentage
        XCTAssertEqual(created.progressPercentage(currentMinutes: 50), 50.0, accuracy: 0.1)
        XCTAssertEqual(created.progressPercentage(currentMinutes: 150), 100.0, accuracy: 0.1)
    }

    func testMultipleActiveGoalsPerChild_AllRetrieved() async throws {
        // Test that a child can have multiple active goals simultaneously
        let categories = try (0..<10).map { i -> TestCategory in
            let category = TestCategory(
                name: "Category \(i)",
                iconName: "star.fill",
                colorHex: "#4A90D9",
                childId: testChild.id
            )
            try createCategoryEntity(category)
            return category
        }

        // Create active goal for each category
        for category in categories {
            let goal = TimeGoal(
                categoryId: category.id,
                childId: testChild.id,
                recommendedMinutes: 60,
                isActive: true
            )
            _ = try await sut.create(goal)
        }

        // Act
        let active = try await sut.fetchActive(for: testChild.id)

        // Assert
        XCTAssertEqual(active.count, 10, "Should support multiple active goals per child")
        XCTAssertTrue(active.allSatisfy { $0.isActive })
    }

    func testUpdatePreservesImmutableFields() async throws {
        // Ensure ID, categoryId, childId, and createdDate don't change on update
        let timeGoal = TimeGoal(
            categoryId: testCategory.id,
            childId: testChild.id,
            recommendedMinutes: 60,
            createdDate: Date()
        )
        let created = try await sut.create(timeGoal)

        // Store original values
        let originalId = created.id
        let originalCategoryId = created.categoryId
        let originalChildId = created.childId
        let originalCreatedDate = created.createdDate

        // Act: Update mutable fields
        var updated = created
        updated.recommendedMinutes = 120
        updated.warningThreshold = 90
        updated.isActive = false
        let result = try await sut.update(updated)

        // Assert: Immutable fields unchanged
        XCTAssertEqual(result.id, originalId)
        XCTAssertEqual(result.categoryId, originalCategoryId)
        XCTAssertEqual(result.childId, originalChildId)
        XCTAssertEqual(result.createdDate.timeIntervalSince1970,
                      originalCreatedDate.timeIntervalSince1970,
                      accuracy: 1.0)

        // Mutable fields changed
        XCTAssertEqual(result.recommendedMinutes, 120)
        XCTAssertEqual(result.warningThreshold, 90)
        XCTAssertFalse(result.isActive)
    }

    // MARK: - Helper Methods

    /// Creates a ChildEntity in the test context for testing relationships
    private func createChildEntity(_ child: Child) throws {
        testContext.performAndWait {
            let entity = ChildEntity(context: testContext)
            entity.id = child.id
            entity.name = child.name
            entity.age = Int16(child.age)
            entity.avatarId = child.avatarId
            entity.themeColor = child.themeColor
            entity.createdDate = child.createdDate
            entity.lastActiveDate = child.lastActiveDate
            entity.isActive = child.isActive

            do {
                try testContext.save()
            } catch {
                XCTFail("Failed to create test child entity: \(error)")
            }
        }
    }

    /// Creates a CategoryEntity in the test context for testing relationships
    private func createCategoryEntity(_ category: TestCategory) throws {
        testContext.performAndWait {
            let entity = CategoryEntity(context: testContext)
            entity.id = category.id
            entity.name = category.name
            entity.iconName = category.iconName
            entity.colorHex = category.colorHex
            entity.isActive = category.isActive
            entity.sortOrder = Int16(category.sortOrder)
            entity.isSystem = category.isSystem
            entity.recommendedDuration = category.recommendedDuration

            // Link to child entity
            let childRequest = ChildEntity.fetchRequest()
            childRequest.predicate = NSPredicate(format: "id == %@", category.childId as CVarArg)
            childRequest.fetchLimit = 1

            do {
                if let childEntity = try testContext.fetch(childRequest).first {
                    entity.child = childEntity
                }
                try testContext.save()
            } catch {
                XCTFail("Failed to create test category entity: \(error)")
            }
        }
    }
}
