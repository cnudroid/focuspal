//
//  CoreDataAchievementRepositoryTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import CoreData
@testable import FocusPal

/// Comprehensive tests for CoreDataAchievementRepository
/// Tests all CRUD operations and specialized queries
final class CoreDataAchievementRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataAchievementRepository!
    var testContext: NSManagedObjectContext!
    var testChild: Child!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Setup test CoreData stack
        let testStack = TestCoreDataStack.shared
        testStack.clearAllData()
        testContext = testStack.newTestContext()

        // Initialize repository with test context
        sut = CoreDataAchievementRepository(context: testContext)

        // Create test child
        testChild = Child(name: "Test Child", age: 10)
        try createChildEntity(testChild)
    }

    override func tearDownWithError() throws {
        sut = nil
        testContext = nil
        testChild = nil
        TestCoreDataStack.shared.clearAllData()
        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithValidAchievement_SavesSuccessfully() async throws {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )

        // Act
        let created = try await sut.create(achievement)

        // Assert
        XCTAssertEqual(created.id, achievement.id, "Created achievement should have same ID")
        XCTAssertEqual(created.achievementTypeId, achievement.achievementTypeId)
        XCTAssertEqual(created.childId, achievement.childId)
        XCTAssertEqual(created.progress, 0)
        XCTAssertEqual(created.targetValue, 1)
        XCTAssertNil(created.unlockedDate)
    }

    func testCreate_WithUnlockedAchievement_SavesWithDate() async throws {
        // Arrange
        let unlockDate = Date()
        let achievement = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            unlockedDate: unlockDate,
            progress: 3,
            targetValue: 3
        )

        // Act
        let created = try await sut.create(achievement)

        // Assert
        XCTAssertNotNil(created.unlockedDate)
        XCTAssertEqual(created.progress, 3)
        XCTAssertTrue(created.isUnlocked)
    }

    func testCreate_MultipleAchievements_AllSavedSuccessfully() async throws {
        // Arrange
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            targetValue: 3
        )

        // Act
        let created1 = try await sut.create(achievement1)
        let created2 = try await sut.create(achievement2)

        // Assert
        XCTAssertNotEqual(created1.id, created2.id)
        XCTAssertNotEqual(created1.achievementTypeId, created2.achievementTypeId)
    }

    // MARK: - FetchAll Tests

    func testFetchAll_WithNoAchievements_ReturnsEmptyArray() async throws {
        // Act
        let achievements = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertTrue(achievements.isEmpty, "Should return empty array when no achievements exist")
    }

    func testFetchAll_WithMultipleAchievements_ReturnsAllForChild() async throws {
        // Arrange: Create 3 achievements for test child
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            targetValue: 3
        )
        let achievement3 = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            targetValue: 600
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)
        _ = try await sut.create(achievement3)

        // Act
        let achievements = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(achievements.count, 3, "Should return all achievements for child")
        let typeIds = Set(achievements.map { $0.achievementTypeId })
        XCTAssertTrue(typeIds.contains(AchievementType.firstTimer.rawValue))
        XCTAssertTrue(typeIds.contains(AchievementType.streak3Day.rawValue))
        XCTAssertTrue(typeIds.contains(AchievementType.homeworkHero.rawValue))
    }

    func testFetchAll_OnlyReturnsAchievementsForSpecificChild() async throws {
        // Arrange: Create another child and achievement
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: otherChild.id,
            targetValue: 3
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)

        // Act
        let achievements = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(achievements.count, 1, "Should only return achievements for specific child")
        XCTAssertEqual(achievements[0].childId, testChild.id)
    }

    func testFetchAll_ReturnsSortedByTypeId() async throws {
        // Arrange: Create achievements in random order
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.streak7Day.rawValue,
            childId: testChild.id,
            targetValue: 7
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        let achievement3 = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            targetValue: 600
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)
        _ = try await sut.create(achievement3)

        // Act
        let achievements = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(achievements.count, 3)
        // Verify sorted alphabetically by achievementTypeId
        let typeIds = achievements.map { $0.achievementTypeId }
        let sortedTypeIds = typeIds.sorted()
        XCTAssertEqual(typeIds, sortedTypeIds, "Achievements should be sorted by achievementTypeId")
    }

    // MARK: - Fetch by ChildId and Type Tests

    func testFetch_WithValidChildAndType_ReturnsAchievement() async throws {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            progress: 1,
            targetValue: 1
        )
        _ = try await sut.create(achievement)

        // Act
        let fetched = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.firstTimer.rawValue
        )

        // Assert
        XCTAssertNotNil(fetched, "Should find achievement")
        XCTAssertEqual(fetched?.id, achievement.id)
        XCTAssertEqual(fetched?.achievementTypeId, AchievementType.firstTimer.rawValue)
        XCTAssertEqual(fetched?.childId, testChild.id)
        XCTAssertEqual(fetched?.progress, 1)
    }

    func testFetch_WithNonExistentType_ReturnsNil() async throws {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        _ = try await sut.create(achievement)

        // Act
        let fetched = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.streak7Day.rawValue
        )

        // Assert
        XCTAssertNil(fetched, "Should return nil for non-existent achievement type")
    }

    func testFetch_WithWrongChildId_ReturnsNil() async throws {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        _ = try await sut.create(achievement)

        // Act
        let wrongChildId = UUID()
        let fetched = try await sut.fetch(
            for: wrongChildId,
            achievementTypeId: AchievementType.firstTimer.rawValue
        )

        // Assert
        XCTAssertNil(fetched, "Should return nil for wrong child ID")
    }

    // MARK: - Update Tests

    func testUpdate_WithExistingAchievement_UpdatesSuccessfully() async throws {
        // Arrange: Create initial achievement
        let achievement = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            progress: 1,
            targetValue: 3
        )
        let created = try await sut.create(achievement)

        // Act: Update progress
        var updated = created
        updated.progress = 2
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.progress, 2)

        // Verify persistence
        let fetched = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.streak3Day.rawValue
        )
        XCTAssertEqual(fetched?.progress, 2)
    }

    func testUpdate_UnlocksAchievement_SavesUnlockDate() async throws {
        // Arrange: Create locked achievement
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            progress: 0,
            targetValue: 1
        )
        let created = try await sut.create(achievement)

        // Act: Unlock achievement
        var unlocked = created
        unlocked.progress = 1
        unlocked.unlockedDate = Date()
        let result = try await sut.update(unlocked)

        // Assert
        XCTAssertNotNil(result.unlockedDate)
        XCTAssertTrue(result.isUnlocked)

        // Verify persistence
        let fetched = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.firstTimer.rawValue
        )
        XCTAssertNotNil(fetched?.unlockedDate)
        XCTAssertEqual(fetched?.progress, 1)
    }

    func testUpdate_WithNonExistentId_ThrowsError() async throws {
        // Arrange: Create achievement with ID that doesn't exist
        let achievement = Achievement(
            id: UUID(),  // Non-existent ID
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )

        // Act & Assert
        do {
            _ = try await sut.update(achievement)
            XCTFail("Should throw error for non-existent achievement")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    func testUpdate_IncrementProgress_WorksCorrectly() async throws {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            progress: 100,
            targetValue: 600
        )
        let created = try await sut.create(achievement)

        // Act: Increment progress multiple times
        var current = created
        for i in 1...5 {
            current.progress = 100 + (i * 50)
            current = try await sut.update(current)
        }

        // Assert
        XCTAssertEqual(current.progress, 350)

        let fetched = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.homeworkHero.rawValue
        )
        XCTAssertEqual(fetched?.progress, 350)
    }

    // MARK: - Delete Tests

    func testDelete_WithExistingId_DeletesSuccessfully() async throws {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        let created = try await sut.create(achievement)

        // Verify it exists
        let beforeDelete = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.firstTimer.rawValue
        )
        XCTAssertNotNil(beforeDelete)

        // Act
        try await sut.delete(created.id)

        // Assert
        let afterDelete = try await sut.fetch(
            for: testChild.id,
            achievementTypeId: AchievementType.firstTimer.rawValue
        )
        XCTAssertNil(afterDelete, "Achievement should be deleted")
    }

    func testDelete_WithNonExistentId_ThrowsError() async throws {
        // Arrange
        let nonExistentId = UUID()

        // Act & Assert
        do {
            try await sut.delete(nonExistentId)
            XCTFail("Should throw error for non-existent achievement")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    func testDelete_DoesNotAffectOtherAchievements() async throws {
        // Arrange: Create multiple achievements
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            targetValue: 3
        )

        let created1 = try await sut.create(achievement1)
        let created2 = try await sut.create(achievement2)

        // Act: Delete only first achievement
        try await sut.delete(created1.id)

        // Assert: Second achievement still exists
        let remaining = try await sut.fetchAll(for: testChild.id)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, created2.id)
    }

    // MARK: - FetchUnlocked Tests

    func testFetchUnlocked_WithNoUnlockedAchievements_ReturnsEmptyArray() async throws {
        // Arrange: Create only locked achievements
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            progress: 0,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            progress: 1,
            targetValue: 3
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)

        // Act
        let unlocked = try await sut.fetchUnlocked(for: testChild.id)

        // Assert
        XCTAssertTrue(unlocked.isEmpty, "Should return empty array when no achievements unlocked")
    }

    func testFetchUnlocked_WithUnlockedAchievements_ReturnsOnlyUnlocked() async throws {
        // Arrange: Create mix of locked and unlocked achievements
        let unlockedDate1 = Date().addingTimeInterval(-86400) // Yesterday
        let unlockedDate2 = Date() // Today

        let unlocked1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: unlockedDate1,
            progress: 1,
            targetValue: 1
        )
        let locked = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            progress: 2,
            targetValue: 3
        )
        let unlocked2 = Achievement(
            achievementTypeId: AchievementType.earlyBird.rawValue,
            childId: testChild.id,
            unlockedDate: unlockedDate2,
            progress: 1,
            targetValue: 1
        )

        _ = try await sut.create(unlocked1)
        _ = try await sut.create(locked)
        _ = try await sut.create(unlocked2)

        // Act
        let unlockedAchievements = try await sut.fetchUnlocked(for: testChild.id)

        // Assert
        XCTAssertEqual(unlockedAchievements.count, 2, "Should return only unlocked achievements")
        XCTAssertTrue(unlockedAchievements.allSatisfy { $0.isUnlocked })

        let typeIds = Set(unlockedAchievements.map { $0.achievementTypeId })
        XCTAssertTrue(typeIds.contains(AchievementType.firstTimer.rawValue))
        XCTAssertTrue(typeIds.contains(AchievementType.earlyBird.rawValue))
        XCTAssertFalse(typeIds.contains(AchievementType.streak3Day.rawValue))
    }

    func testFetchUnlocked_SortsByUnlockDateDescending() async throws {
        // Arrange: Create unlocked achievements at different times
        let oldDate = Date().addingTimeInterval(-172800) // 2 days ago
        let middleDate = Date().addingTimeInterval(-86400) // Yesterday
        let recentDate = Date() // Today

        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: middleDate,
            progress: 1,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.earlyBird.rawValue,
            childId: testChild.id,
            unlockedDate: recentDate,
            progress: 1,
            targetValue: 1
        )
        let achievement3 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            unlockedDate: oldDate,
            progress: 3,
            targetValue: 3
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)
        _ = try await sut.create(achievement3)

        // Act
        let unlocked = try await sut.fetchUnlocked(for: testChild.id)

        // Assert
        XCTAssertEqual(unlocked.count, 3)
        // Should be sorted by unlock date descending (most recent first)
        XCTAssertEqual(unlocked[0].achievementTypeId, AchievementType.earlyBird.rawValue)
        XCTAssertEqual(unlocked[1].achievementTypeId, AchievementType.firstTimer.rawValue)
        XCTAssertEqual(unlocked[2].achievementTypeId, AchievementType.streak3Day.rawValue)
    }

    func testFetchUnlocked_OnlyReturnsForSpecificChild() async throws {
        // Arrange: Create another child with unlocked achievement
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let testChildAchievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            progress: 1,
            targetValue: 1
        )
        let otherChildAchievement = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: otherChild.id,
            unlockedDate: Date(),
            progress: 3,
            targetValue: 3
        )

        _ = try await sut.create(testChildAchievement)
        _ = try await sut.create(otherChildAchievement)

        // Act
        let unlocked = try await sut.fetchUnlocked(for: testChild.id)

        // Assert
        XCTAssertEqual(unlocked.count, 1, "Should only return unlocked achievements for specific child")
        XCTAssertEqual(unlocked[0].childId, testChild.id)
    }

    // MARK: - FetchLocked Tests

    func testFetchLocked_WithNoLockedAchievements_ReturnsEmptyArray() async throws {
        // Arrange: Create only unlocked achievements
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            progress: 1,
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.earlyBird.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            progress: 1,
            targetValue: 1
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)

        // Act
        let locked = try await sut.fetchLocked(for: testChild.id)

        // Assert
        XCTAssertTrue(locked.isEmpty, "Should return empty array when all achievements unlocked")
    }

    func testFetchLocked_WithLockedAchievements_ReturnsOnlyLocked() async throws {
        // Arrange: Create mix of locked and unlocked achievements
        let locked1 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            progress: 1,
            targetValue: 3
        )
        let unlocked = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            unlockedDate: Date(),
            progress: 1,
            targetValue: 1
        )
        let locked2 = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            progress: 200,
            targetValue: 600
        )

        _ = try await sut.create(locked1)
        _ = try await sut.create(unlocked)
        _ = try await sut.create(locked2)

        // Act
        let lockedAchievements = try await sut.fetchLocked(for: testChild.id)

        // Assert
        XCTAssertEqual(lockedAchievements.count, 2, "Should return only locked achievements")
        XCTAssertTrue(lockedAchievements.allSatisfy { !$0.isUnlocked })

        let typeIds = Set(lockedAchievements.map { $0.achievementTypeId })
        XCTAssertTrue(typeIds.contains(AchievementType.streak3Day.rawValue))
        XCTAssertTrue(typeIds.contains(AchievementType.homeworkHero.rawValue))
        XCTAssertFalse(typeIds.contains(AchievementType.firstTimer.rawValue))
    }

    func testFetchLocked_SortsByTypeIdAscending() async throws {
        // Arrange: Create locked achievements in random order
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.streak7Day.rawValue,
            childId: testChild.id,
            progress: 3,
            targetValue: 7
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: testChild.id,
            progress: 0,
            targetValue: 1
        )
        let achievement3 = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            progress: 100,
            targetValue: 600
        )

        _ = try await sut.create(achievement1)
        _ = try await sut.create(achievement2)
        _ = try await sut.create(achievement3)

        // Act
        let locked = try await sut.fetchLocked(for: testChild.id)

        // Assert
        XCTAssertEqual(locked.count, 3)
        // Should be sorted alphabetically by achievementTypeId
        let typeIds = locked.map { $0.achievementTypeId }
        let sortedTypeIds = typeIds.sorted()
        XCTAssertEqual(typeIds, sortedTypeIds, "Locked achievements should be sorted by achievementTypeId")
    }

    func testFetchLocked_OnlyReturnsForSpecificChild() async throws {
        // Arrange: Create another child with locked achievement
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let testChildAchievement = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: testChild.id,
            progress: 1,
            targetValue: 3
        )
        let otherChildAchievement = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: otherChild.id,
            progress: 200,
            targetValue: 600
        )

        _ = try await sut.create(testChildAchievement)
        _ = try await sut.create(otherChildAchievement)

        // Act
        let locked = try await sut.fetchLocked(for: testChild.id)

        // Assert
        XCTAssertEqual(locked.count, 1, "Should only return locked achievements for specific child")
        XCTAssertEqual(locked[0].childId, testChild.id)
    }

    // MARK: - Edge Cases & Integration Tests

    func testAchievementLifecycle_CreateUpdateUnlockDelete() async throws {
        // Test complete lifecycle of an achievement

        // 1. Create locked achievement
        let achievement = Achievement(
            achievementTypeId: AchievementType.streak7Day.rawValue,
            childId: testChild.id,
            progress: 0,
            targetValue: 7
        )
        let created = try await sut.create(achievement)

        // 2. Verify it's in locked list
        var locked = try await sut.fetchLocked(for: testChild.id)
        XCTAssertEqual(locked.count, 1)

        // 3. Update progress incrementally
        var current = created
        for day in 1...6 {
            current.progress = day
            current = try await sut.update(current)
            XCTAssertEqual(current.progress, day)
        }

        // 4. Complete and unlock
        current.progress = 7
        current.unlockedDate = Date()
        current = try await sut.update(current)

        // 5. Verify it moved to unlocked list
        let unlocked = try await sut.fetchUnlocked(for: testChild.id)
        XCTAssertEqual(unlocked.count, 1)
        XCTAssertTrue(unlocked[0].isUnlocked)

        locked = try await sut.fetchLocked(for: testChild.id)
        XCTAssertTrue(locked.isEmpty)

        // 6. Delete achievement
        try await sut.delete(current.id)

        // 7. Verify it's gone
        let all = try await sut.fetchAll(for: testChild.id)
        XCTAssertTrue(all.isEmpty)
    }

    func testConcurrentOperations_DoNotCorruptData() async throws {
        // Test concurrent creates and updates
        let achievements = (0..<5).map { i in
            Achievement(
                achievementTypeId: "test_type_\(i)",
                childId: testChild.id,
                progress: 0,
                targetValue: 10
            )
        }

        // Create all concurrently
        try await withThrowingTaskGroup(of: Achievement.self) { group in
            for achievement in achievements {
                group.addTask {
                    try await self.sut.create(achievement)
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

    func testProgressPercentage_CalculatesCorrectly() async throws {
        // Test that domain model calculations work with persisted data
        let achievement = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: testChild.id,
            progress: 300,
            targetValue: 600
        )

        let created = try await sut.create(achievement)
        XCTAssertEqual(created.progressPercentage, 50.0, accuracy: 0.1)

        // Update to 100%
        var updated = created
        updated.progress = 600
        let result = try await sut.update(updated)
        XCTAssertEqual(result.progressPercentage, 100.0, accuracy: 0.1)
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
}
