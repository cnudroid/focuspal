//
//  CoreDataRewardsRepositoryTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import CoreData
@testable import FocusPal

/// Comprehensive tests for CoreDataRewardsRepository
/// Tests all CRUD operations and specialized queries
final class CoreDataRewardsRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataRewardsRepository!
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
        sut = CoreDataRewardsRepository(context: testContext)

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

    func testCreate_WithValidReward_SavesSuccessfully() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 150,
            tier: .bronze
        )

        // Act
        let created = try await sut.create(reward)

        // Assert
        XCTAssertEqual(created.id, reward.id, "Created reward should have same ID")
        XCTAssertEqual(created.childId, testChild.id)
        XCTAssertEqual(created.totalPoints, 150)
        XCTAssertEqual(created.tier, .bronze)
        XCTAssertFalse(created.isRedeemed)
        XCTAssertNil(created.redeemedDate)
    }

    func testCreate_WithRedeemedReward_SavesCorrectly() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let redeemDate = Date()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 500,
            tier: .gold,
            isRedeemed: true,
            redeemedDate: redeemDate
        )

        // Act
        let created = try await sut.create(reward)

        // Assert
        XCTAssertTrue(created.isRedeemed)
        XCTAssertNotNil(created.redeemedDate)
        XCTAssertEqual(created.tier, .gold)
    }

    func testCreate_WithNoTier_SavesCorrectly() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 50,
            tier: nil
        )

        // Act
        let created = try await sut.create(reward)

        // Assert
        XCTAssertNil(created.tier)
        XCTAssertEqual(created.totalPoints, 50)
    }

    // MARK: - FetchAll Tests

    func testFetchAll_WithNoRewards_ReturnsEmptyArray() async throws {
        // Act
        let rewards = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertTrue(rewards.isEmpty, "Should return empty array when no rewards exist")
    }

    func testFetchAll_WithMultipleRewards_ReturnsAllForChild() async throws {
        // Arrange: Create rewards for 3 different weeks
        let calendar = Calendar.current
        let today = Date()

        let week1Start = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1Start)

        let week2Start = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2Start)

        let (start3, end3) = WeeklyReward.currentWeekDates()

        let reward1 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 200,
            tier: .silver
        )
        let reward2 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start2,
            weekEndDate: end2,
            totalPoints: 600,
            tier: .gold
        )
        let reward3 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start3,
            weekEndDate: end3,
            totalPoints: 100,
            tier: .bronze
        )

        _ = try await sut.create(reward1)
        _ = try await sut.create(reward2)
        _ = try await sut.create(reward3)

        // Act
        let rewards = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(rewards.count, 3, "Should return all rewards for child")
    }

    func testFetchAll_SortsByWeekStartDateDescending() async throws {
        // Arrange: Create rewards at different weeks
        let calendar = Calendar.current
        let today = Date()

        let week1Start = calendar.date(byAdding: .day, value: -21, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1Start)

        let week2Start = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2Start)

        let (start3, end3) = WeeklyReward.currentWeekDates()

        let reward1 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 200
        )
        let reward2 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start2,
            weekEndDate: end2,
            totalPoints: 300
        )
        let reward3 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start3,
            weekEndDate: end3,
            totalPoints: 100
        )

        _ = try await sut.create(reward1)
        _ = try await sut.create(reward2)
        _ = try await sut.create(reward3)

        // Act
        let rewards = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(rewards.count, 3)
        // Should be sorted by week start date descending (most recent first)
        XCTAssertEqual(rewards[0].totalPoints, 100) // Current week
        XCTAssertEqual(rewards[1].totalPoints, 300) // Last week
        XCTAssertEqual(rewards[2].totalPoints, 200) // Two weeks ago
    }

    func testFetchAll_OnlyReturnsRewardsForSpecificChild() async throws {
        // Arrange: Create another child and reward
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let (start1, end1) = WeeklyReward.currentWeekDates()
        let reward1 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 200
        )
        let reward2 = WeeklyReward(
            childId: otherChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 300
        )

        _ = try await sut.create(reward1)
        _ = try await sut.create(reward2)

        // Act
        let rewards = try await sut.fetchAll(for: testChild.id)

        // Assert
        XCTAssertEqual(rewards.count, 1, "Should only return rewards for specific child")
        XCTAssertEqual(rewards[0].childId, testChild.id)
    }

    // MARK: - FetchRewards (Date Range) Tests

    func testFetchRewards_WithDateRange_ReturnsOnlyMatchingRewards() async throws {
        // Arrange: Create rewards for multiple weeks using explicit week boundaries
        let calendar = Calendar.current
        let (currentWeekStart, _) = WeeklyReward.currentWeekDates()

        // Create week starts exactly 7 days apart for predictable behavior
        let start3 = calendar.date(byAdding: .day, value: -7, to: currentWeekStart)!
        let end3 = calendar.date(byAdding: .day, value: 7, to: start3)!

        let start2 = calendar.date(byAdding: .day, value: -14, to: currentWeekStart)!
        let end2 = calendar.date(byAdding: .day, value: 7, to: start2)!

        let start1 = calendar.date(byAdding: .day, value: -21, to: currentWeekStart)!
        let end1 = calendar.date(byAdding: .day, value: 7, to: start1)!

        let reward1 = WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 100)
        let reward2 = WeeklyReward(childId: testChild.id, weekStartDate: start2, weekEndDate: end2, totalPoints: 200)
        let reward3 = WeeklyReward(childId: testChild.id, weekStartDate: start3, weekEndDate: end3, totalPoints: 300)

        _ = try await sut.create(reward1)
        _ = try await sut.create(reward2)
        _ = try await sut.create(reward3)

        // Act: Fetch rewards for the two most recent past weeks (start2 and start3)
        // Use start2 as range start (includes start2 and start3) and end3 as range end
        let rewards = try await sut.fetchRewards(for: testChild.id, from: start2, to: end3)

        // Assert: Should return rewards 2 and 3 (within date range)
        XCTAssertEqual(rewards.count, 2)
        XCTAssertTrue(rewards.contains(where: { $0.totalPoints == 200 }))
        XCTAssertTrue(rewards.contains(where: { $0.totalPoints == 300 }))
    }

    // MARK: - FetchReward (Specific Week) Tests

    func testFetchReward_ForSpecificWeek_ReturnsCorrectReward() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 250,
            tier: .silver
        )
        _ = try await sut.create(reward)

        // Act
        let fetched = try await sut.fetchReward(for: testChild.id, weekStartDate: weekStart)

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.totalPoints, 250)
        XCTAssertEqual(fetched?.tier, .silver)
    }

    func testFetchReward_ForNonExistentWeek_ReturnsNil() async throws {
        // Arrange
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 30, to: Date())!
        let (weekStart, _) = WeeklyReward.weekDates(for: futureDate)

        // Act
        let fetched = try await sut.fetchReward(for: testChild.id, weekStartDate: weekStart)

        // Assert
        XCTAssertNil(fetched, "Should return nil for non-existent week")
    }

    // MARK: - Fetch by ID Tests

    func testFetch_ById_WithValidId_ReturnsReward() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 750,
            tier: .gold
        )
        let created = try await sut.create(reward)

        // Act
        let fetched = try await sut.fetch(by: created.id)

        // Assert
        XCTAssertNotNil(fetched, "Should find reward by ID")
        XCTAssertEqual(fetched?.id, created.id)
        XCTAssertEqual(fetched?.totalPoints, 750)
        XCTAssertEqual(fetched?.tier, .gold)
    }

    func testFetch_ById_WithNonExistentId_ReturnsNil() async throws {
        // Arrange
        let nonExistentId = UUID()

        // Act
        let fetched = try await sut.fetch(by: nonExistentId)

        // Assert
        XCTAssertNil(fetched, "Should return nil for non-existent ID")
    }

    // MARK: - Update Tests

    func testUpdate_WithExistingReward_UpdatesSuccessfully() async throws {
        // Arrange: Create initial reward
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 150,
            tier: .bronze
        )
        let created = try await sut.create(reward)

        // Act: Update points and tier
        var updated = created
        updated.totalPoints = 600
        updated.tier = .gold
        let result = try await sut.update(updated)

        // Assert
        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.totalPoints, 600)
        XCTAssertEqual(result.tier, .gold)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertEqual(fetched?.totalPoints, 600)
        XCTAssertEqual(fetched?.tier, .gold)
    }

    func testUpdate_RedeemsReward_SavesCorrectly() async throws {
        // Arrange: Create unredeemed reward
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 500,
            tier: .gold,
            isRedeemed: false
        )
        let created = try await sut.create(reward)
        XCTAssertFalse(created.isRedeemed)

        // Act: Redeem reward
        var updated = created
        updated.isRedeemed = true
        updated.redeemedDate = Date()
        let result = try await sut.update(updated)

        // Assert
        XCTAssertTrue(result.isRedeemed)
        XCTAssertNotNil(result.redeemedDate)

        // Verify persistence
        let fetched = try await sut.fetch(by: created.id)
        XCTAssertTrue(fetched!.isRedeemed)
        XCTAssertNotNil(fetched?.redeemedDate)
    }

    func testUpdate_WithNonExistentId_ThrowsError() async throws {
        // Arrange: Create reward with ID that doesn't exist
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            id: UUID(),  // Non-existent ID
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 100
        )

        // Act & Assert
        do {
            _ = try await sut.update(reward)
            XCTFail("Should throw error for non-existent reward")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    // MARK: - Delete Tests

    func testDelete_WithExistingId_DeletesSuccessfully() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 200
        )
        let created = try await sut.create(reward)

        // Verify it exists
        let beforeDelete = try await sut.fetch(by: created.id)
        XCTAssertNotNil(beforeDelete)

        // Act
        try await sut.delete(created.id)

        // Assert
        let afterDelete = try await sut.fetch(by: created.id)
        XCTAssertNil(afterDelete, "Reward should be deleted")
    }

    func testDelete_WithNonExistentId_ThrowsError() async throws {
        // Arrange
        let nonExistentId = UUID()

        // Act & Assert
        do {
            try await sut.delete(nonExistentId)
            XCTFail("Should throw error for non-existent reward")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.entityNotFound)
        }
    }

    // MARK: - FetchUnredeemed Tests

    func testFetchUnredeemed_WithNoUnredeemedRewards_ReturnsEmptyArray() async throws {
        // Arrange: Create only redeemed rewards
        let (start1, end1) = WeeklyReward.currentWeekDates()
        let reward1 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 200,
            tier: .silver,
            isRedeemed: true,
            redeemedDate: Date()
        )
        _ = try await sut.create(reward1)

        // Act
        let unredeemed = try await sut.fetchUnredeemed(for: testChild.id)

        // Assert
        XCTAssertTrue(unredeemed.isEmpty, "Should return empty array when no unredeemed rewards")
    }

    func testFetchUnredeemed_WithUnredeemedRewards_ReturnsOnlyUnredeemed() async throws {
        // Arrange: Create mix of redeemed and unredeemed rewards
        let calendar = Calendar.current
        let today = Date()

        let week1Start = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1Start)

        let week2Start = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2Start)

        let (start3, end3) = WeeklyReward.currentWeekDates()

        let redeemedReward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 300,
            tier: .silver,
            isRedeemed: true,
            redeemedDate: Date()
        )
        let unredeemedReward1 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start2,
            weekEndDate: end2,
            totalPoints: 500,
            tier: .gold,
            isRedeemed: false
        )
        let unredeemedReward2 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start3,
            weekEndDate: end3,
            totalPoints: 150,
            tier: .bronze,
            isRedeemed: false
        )

        _ = try await sut.create(redeemedReward)
        _ = try await sut.create(unredeemedReward1)
        _ = try await sut.create(unredeemedReward2)

        // Act
        let unredeemed = try await sut.fetchUnredeemed(for: testChild.id)

        // Assert
        XCTAssertEqual(unredeemed.count, 2, "Should return only unredeemed rewards")
        XCTAssertTrue(unredeemed.allSatisfy { !$0.isRedeemed })
    }

    // MARK: - FetchWithTiers Tests

    func testFetchWithTiers_WithNoTierRewards_ReturnsEmptyArray() async throws {
        // Arrange: Create only rewards without tiers
        let (start1, end1) = WeeklyReward.currentWeekDates()
        let reward1 = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 50,
            tier: nil
        )
        _ = try await sut.create(reward1)

        // Act
        let withTiers = try await sut.fetchWithTiers(for: testChild.id)

        // Assert
        XCTAssertTrue(withTiers.isEmpty, "Should return empty array when no rewards have tiers")
    }

    func testFetchWithTiers_WithTierRewards_ReturnsOnlyWithTiers() async throws {
        // Arrange: Create mix of rewards with and without tiers
        let calendar = Calendar.current
        let today = Date()

        let week1Start = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1Start)

        let week2Start = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2Start)

        let (start3, end3) = WeeklyReward.currentWeekDates()

        let noTierReward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start1,
            weekEndDate: end1,
            totalPoints: 80,
            tier: nil
        )
        let bronzeReward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start2,
            weekEndDate: end2,
            totalPoints: 150,
            tier: .bronze
        )
        let goldReward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start3,
            weekEndDate: end3,
            totalPoints: 550,
            tier: .gold
        )

        _ = try await sut.create(noTierReward)
        _ = try await sut.create(bronzeReward)
        _ = try await sut.create(goldReward)

        // Act
        let withTiers = try await sut.fetchWithTiers(for: testChild.id)

        // Assert
        XCTAssertEqual(withTiers.count, 2, "Should return only rewards with tiers")
        XCTAssertTrue(withTiers.allSatisfy { $0.tier != nil })
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
