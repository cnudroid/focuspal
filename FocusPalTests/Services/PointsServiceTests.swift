//
//  PointsServiceTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import CoreData
@testable import FocusPal

/// Comprehensive tests for PointsService
/// Tests all business logic for awarding, deducting, and tracking points
final class PointsServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: PointsService!
    var repository: CoreDataPointsRepository!
    var testContext: NSManagedObjectContext!
    var testChild: Child!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Setup test CoreData stack
        let testStack = TestCoreDataStack.shared
        testStack.clearAllData()
        testContext = testStack.newTestContext()

        // Initialize repository and service
        repository = CoreDataPointsRepository(context: testContext)
        sut = PointsService(repository: repository)

        // Create test child
        testChild = Child(name: "Test Child", age: 10)
        try createChildEntity(testChild)
    }

    override func tearDownWithError() throws {
        sut = nil
        repository = nil
        testContext = nil
        testChild = nil
        TestCoreDataStack.shared.clearAllData()
        try super.tearDownWithError()
    }

    // MARK: - Award Points Tests

    func testAwardPoints_ForActivityComplete_AwardsCorrectAmount() async throws {
        // Arrange
        let activityId = UUID()

        // Act
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.activityComplete,
            reason: .activityComplete,
            activityId: activityId
        )

        // Assert
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.pointsEarned, 10)
        XCTAssertEqual(todayPoints.totalPoints, 10)

        // Verify transaction was created
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].amount, 10)
        XCTAssertEqual(transactions[0].reason, .activityComplete)
        XCTAssertEqual(transactions[0].activityId, activityId)
    }

    func testAwardPoints_WithBonusPoints_AddsToBonusCategory() async throws {
        // Act
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.earlyFinishBonus,
            reason: .earlyFinishBonus,
            activityId: nil
        )

        // Assert
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.bonusPoints, 5)
        XCTAssertEqual(todayPoints.pointsEarned, 0)
        XCTAssertEqual(todayPoints.totalPoints, 5)
    }

    func testAwardPoints_MultipleAwards_AccumulatesCorrectly() async throws {
        // Act: Award points multiple times
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.activityComplete,
            reason: .activityComplete,
            activityId: UUID()
        )
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.activityComplete,
            reason: .activityComplete,
            activityId: UUID()
        )
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.earlyFinishBonus,
            reason: .earlyFinishBonus,
            activityId: nil
        )

        // Assert
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.pointsEarned, 20) // 10 + 10
        XCTAssertEqual(todayPoints.bonusPoints, 5)
        XCTAssertEqual(todayPoints.totalPoints, 25)

        // Verify all transactions
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)
        XCTAssertEqual(transactions.count, 3)
    }

    func testAwardPoints_ForAchievementUnlock_AwardsCorrectAmount() async throws {
        // Act
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.achievementUnlock,
            reason: .achievementUnlock,
            activityId: nil
        )

        // Assert
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.bonusPoints, 20)
    }

    func testAwardPoints_WithNegativeAmount_ThrowsError() async throws {
        // Act & Assert
        do {
            try await sut.awardPoints(
                childId: testChild.id,
                amount: -10,
                reason: .activityComplete,
                activityId: nil
            )
            XCTFail("Should throw error for negative amount")
        } catch PointsServiceError.invalidAmount {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAwardPoints_WithZeroAmount_ThrowsError() async throws {
        // Act & Assert
        do {
            try await sut.awardPoints(
                childId: testChild.id,
                amount: 0,
                reason: .activityComplete,
                activityId: nil
            )
            XCTFail("Should throw error for zero amount")
        } catch PointsServiceError.invalidAmount {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Deduct Points Tests

    func testDeductPoints_ForActivityIncomplete_DeductsCorrectAmount() async throws {
        // Arrange: Award some points first
        try await sut.awardPoints(
            childId: testChild.id,
            amount: 20,
            reason: .activityComplete,
            activityId: nil
        )

        // Act
        try await sut.deductPoints(
            childId: testChild.id,
            amount: PointsService.Constants.activityIncomplete,
            reason: .activityIncomplete
        )

        // Assert
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.pointsDeducted, 5)
        XCTAssertEqual(todayPoints.totalPoints, 15) // 20 - 5

        // Verify transaction
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)
        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(transactions[0].amount, -5) // Most recent (negative)
        XCTAssertEqual(transactions[0].reason, .activityIncomplete)
    }

    func testDeductPoints_ForThreeStrikePenalty_DeductsCorrectAmount() async throws {
        // Act
        try await sut.deductPoints(
            childId: testChild.id,
            amount: PointsService.Constants.threeStrikePenalty,
            reason: .threeStrikePenalty
        )

        // Assert
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.pointsDeducted, 15)
        XCTAssertEqual(todayPoints.totalPoints, -15) // Can go negative
    }

    func testDeductPoints_WithNegativeAmount_ThrowsError() async throws {
        // Act & Assert
        do {
            try await sut.deductPoints(
                childId: testChild.id,
                amount: -5,
                reason: .activityIncomplete
            )
            XCTFail("Should throw error for negative amount")
        } catch PointsServiceError.invalidAmount {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testDeductPoints_WithZeroAmount_ThrowsError() async throws {
        // Act & Assert
        do {
            try await sut.deductPoints(
                childId: testChild.id,
                amount: 0,
                reason: .activityIncomplete
            )
            XCTFail("Should throw error for zero amount")
        } catch PointsServiceError.invalidAmount {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Get Today Points Tests

    func testGetTodayPoints_WithNoExistingRecord_CreatesNewRecord() async throws {
        // Act
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(todayPoints.childId, testChild.id)
        XCTAssertEqual(todayPoints.pointsEarned, 0)
        XCTAssertEqual(todayPoints.pointsDeducted, 0)
        XCTAssertEqual(todayPoints.bonusPoints, 0)
        XCTAssertEqual(todayPoints.totalPoints, 0)

        // Verify it's persisted
        let fetched = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(fetched.id, todayPoints.id)
    }

    func testGetTodayPoints_WithExistingRecord_ReturnsExisting() async throws {
        // Arrange: Award some points
        try await sut.awardPoints(
            childId: testChild.id,
            amount: 15,
            reason: .activityComplete,
            activityId: nil
        )

        // Act
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(todayPoints.pointsEarned, 15)
    }

    func testGetTodayPoints_UsesDeterministicId() async throws {
        // Act
        let points1 = try await sut.getTodayPoints(for: testChild.id)
        let points2 = try await sut.getTodayPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(points1.id, points2.id, "Should use deterministic ID")
    }

    // MARK: - Get Weekly Points Tests

    func testGetWeeklyPoints_WithNoPoints_ReturnsZero() async throws {
        // Act
        let weeklyPoints = try await sut.getWeeklyPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(weeklyPoints, 0)
    }

    func testGetWeeklyPoints_WithPointsThisWeek_SumsCorrectly() async throws {
        // Arrange: Award points on different days this week
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get start of current week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        let weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!

        // Award 10 points on day 1 of week (Sunday)
        let day1Points = ChildPoints(
            childId: testChild.id,
            date: weekStart,
            pointsEarned: 10,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await repository.saveChildPoints(day1Points)

        // Award 20 points on day 2 of week (Monday)
        let day2 = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        let day2Points = ChildPoints(
            childId: testChild.id,
            date: day2,
            pointsEarned: 20,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await repository.saveChildPoints(day2Points)

        // Award 15 points on day 3 of week (Tuesday) with deductions and bonus
        let day3 = calendar.date(byAdding: .day, value: 2, to: weekStart)!
        let day3Points = ChildPoints(
            childId: testChild.id,
            date: day3,
            pointsEarned: 15,
            pointsDeducted: 5,
            bonusPoints: 3
        )
        _ = try await repository.saveChildPoints(day3Points)

        // Act
        let weeklyPoints = try await sut.getWeeklyPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(weeklyPoints, 43) // 10 + 20 + (15 + 3 - 5)
    }

    func testGetWeeklyPoints_OnlyCountsCurrentWeek() async throws {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Award points this week
        try await sut.awardPoints(
            childId: testChild.id,
            amount: 10,
            reason: .activityComplete,
            activityId: nil
        )

        // Award points last week (should not count)
        let lastWeek = calendar.date(byAdding: .day, value: -8, to: today)!
        let lastWeekPoints = ChildPoints(
            childId: testChild.id,
            date: lastWeek,
            pointsEarned: 100,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await repository.saveChildPoints(lastWeekPoints)

        // Act
        let weeklyPoints = try await sut.getWeeklyPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(weeklyPoints, 10, "Should only count current week")
    }

    // MARK: - Get Total Points Tests

    func testGetTotalPoints_WithNoPoints_ReturnsZero() async throws {
        // Act
        let totalPoints = try await sut.getTotalPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(totalPoints, 0)
    }

    func testGetTotalPoints_SumsAllTimePoints() async throws {
        // Arrange: Award points on multiple days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Today: 10 points
        try await sut.awardPoints(
            childId: testChild.id,
            amount: 10,
            reason: .activityComplete,
            activityId: nil
        )

        // Last week: 50 points
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        let lastWeekPoints = ChildPoints(
            childId: testChild.id,
            date: lastWeek,
            pointsEarned: 50,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await repository.saveChildPoints(lastWeekPoints)

        // Last month: 100 points
        let lastMonth = calendar.date(byAdding: .day, value: -30, to: today)!
        let lastMonthPoints = ChildPoints(
            childId: testChild.id,
            date: lastMonth,
            pointsEarned: 100,
            pointsDeducted: 20,
            bonusPoints: 10
        )
        _ = try await repository.saveChildPoints(lastMonthPoints)

        // Act
        let totalPoints = try await sut.getTotalPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(totalPoints, 150) // 10 + 50 + (100 + 10 - 20)
    }

    func testGetTotalPoints_IncludesNegativePoints() async throws {
        // Arrange
        try await sut.deductPoints(
            childId: testChild.id,
            amount: 15,
            reason: .threeStrikePenalty
        )

        // Act
        let totalPoints = try await sut.getTotalPoints(for: testChild.id)

        // Assert
        XCTAssertEqual(totalPoints, -15, "Should include negative points")
    }

    // MARK: - Get Transaction History Tests

    func testGetTransactionHistory_WithNoTransactions_ReturnsEmptyArray() async throws {
        // Act
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)

        // Assert
        XCTAssertTrue(transactions.isEmpty)
    }

    func testGetTransactionHistory_ReturnsInDescendingOrder() async throws {
        // Arrange: Create multiple transactions
        try await sut.awardPoints(childId: testChild.id, amount: 10, reason: .activityComplete, activityId: nil)
        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        try await sut.awardPoints(childId: testChild.id, amount: 20, reason: .activityComplete, activityId: nil)
        try await Task.sleep(nanoseconds: 10_000_000)
        try await sut.awardPoints(childId: testChild.id, amount: 30, reason: .activityComplete, activityId: nil)

        // Act
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)

        // Assert
        XCTAssertEqual(transactions.count, 3)
        // Most recent first
        XCTAssertEqual(transactions[0].amount, 30)
        XCTAssertEqual(transactions[1].amount, 20)
        XCTAssertEqual(transactions[2].amount, 10)
    }

    func testGetTransactionHistory_RespectsLimit() async throws {
        // Arrange: Create 5 transactions
        for _ in 1...5 {
            try await sut.awardPoints(childId: testChild.id, amount: 10, reason: .activityComplete, activityId: nil)
        }

        // Act
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 3)

        // Assert
        XCTAssertEqual(transactions.count, 3)
    }

    func testGetTransactionHistory_OnlyReturnsForSpecificChild() async throws {
        // Arrange: Create another child
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        try await sut.awardPoints(childId: testChild.id, amount: 10, reason: .activityComplete, activityId: nil)
        try await sut.awardPoints(childId: otherChild.id, amount: 20, reason: .activityComplete, activityId: nil)

        // Act
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)

        // Assert
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].childId, testChild.id)
    }

    // MARK: - Integration Tests

    func testCompletePointsFlow_AwardDeductAndTrack() async throws {
        // 1. Award points for completing activity
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.activityComplete,
            reason: .activityComplete,
            activityId: UUID()
        )

        // 2. Award early finish bonus
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.earlyFinishBonus,
            reason: .earlyFinishBonus,
            activityId: nil
        )

        // 3. Award beat average bonus
        try await sut.awardPoints(
            childId: testChild.id,
            amount: PointsService.Constants.beatAverageBonus,
            reason: .beatAverageBonus,
            activityId: nil
        )

        // 4. Deduct for incomplete activity
        try await sut.deductPoints(
            childId: testChild.id,
            amount: PointsService.Constants.activityIncomplete,
            reason: .activityIncomplete
        )

        // Verify today's points
        let todayPoints = try await sut.getTodayPoints(for: testChild.id)
        XCTAssertEqual(todayPoints.pointsEarned, 10)
        XCTAssertEqual(todayPoints.bonusPoints, 8) // 5 + 3
        XCTAssertEqual(todayPoints.pointsDeducted, 5)
        XCTAssertEqual(todayPoints.totalPoints, 13) // 10 + 8 - 5

        // Verify transaction history
        let transactions = try await sut.getTransactionHistory(for: testChild.id, limit: 10)
        XCTAssertEqual(transactions.count, 4)

        // Verify weekly and total points
        let weeklyPoints = try await sut.getWeeklyPoints(for: testChild.id)
        XCTAssertEqual(weeklyPoints, 13)

        let totalPoints = try await sut.getTotalPoints(for: testChild.id)
        XCTAssertEqual(totalPoints, 13)
    }

    func testPointsConstants_HaveCorrectValues() {
        // Verify the point values match requirements
        XCTAssertEqual(PointsService.Constants.activityComplete, 10)
        XCTAssertEqual(PointsService.Constants.activityIncomplete, 5)
        XCTAssertEqual(PointsService.Constants.earlyFinishBonus, 5)
        XCTAssertEqual(PointsService.Constants.beatAverageBonus, 3)
        XCTAssertEqual(PointsService.Constants.threeStrikePenalty, 15)
        XCTAssertEqual(PointsService.Constants.achievementUnlock, 20)
    }

    // MARK: - Helper Methods

    /// Creates a ChildEntity in the test context for testing
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
