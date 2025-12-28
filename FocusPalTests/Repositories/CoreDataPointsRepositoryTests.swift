//
//  CoreDataPointsRepositoryTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import CoreData
@testable import FocusPal

/// Comprehensive tests for CoreDataPointsRepository
/// Tests all CRUD operations for ChildPoints and PointsTransactions
final class CoreDataPointsRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataPointsRepository!
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
        sut = CoreDataPointsRepository(context: testContext)

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

    // MARK: - ChildPoints Tests

    func testSaveChildPoints_WithNewRecord_CreatesSuccessfully() async throws {
        // Arrange
        let childPoints = ChildPoints(
            childId: testChild.id,
            date: Date(),
            pointsEarned: 10,
            pointsDeducted: 0,
            bonusPoints: 5
        )

        // Act
        let saved = try await sut.saveChildPoints(childPoints)

        // Assert
        XCTAssertEqual(saved.id, childPoints.id)
        XCTAssertEqual(saved.childId, testChild.id)
        XCTAssertEqual(saved.pointsEarned, 10)
        XCTAssertEqual(saved.pointsDeducted, 0)
        XCTAssertEqual(saved.bonusPoints, 5)
        XCTAssertEqual(saved.totalPoints, 15)
    }

    func testSaveChildPoints_WithExistingRecord_UpdatesSuccessfully() async throws {
        // Arrange: Create initial record
        let initialPoints = ChildPoints(
            childId: testChild.id,
            date: Date(),
            pointsEarned: 10,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await sut.saveChildPoints(initialPoints)

        // Act: Update with new values
        let updatedPoints = ChildPoints(
            id: initialPoints.id,
            childId: testChild.id,
            date: initialPoints.date,
            pointsEarned: 20,
            pointsDeducted: 5,
            bonusPoints: 3
        )
        let saved = try await sut.saveChildPoints(updatedPoints)

        // Assert
        XCTAssertEqual(saved.id, initialPoints.id)
        XCTAssertEqual(saved.pointsEarned, 20)
        XCTAssertEqual(saved.pointsDeducted, 5)
        XCTAssertEqual(saved.bonusPoints, 3)
        XCTAssertEqual(saved.totalPoints, 18)

        // Verify no duplicate was created
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: initialPoints.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let dateRange = DateInterval(start: startOfDay, end: endOfDay)
        let allPoints = try await sut.fetchChildPoints(for: testChild.id, dateRange: dateRange)
        XCTAssertEqual(allPoints.count, 1, "Should not create duplicate records")
    }

    func testSaveChildPoints_UsesDeterministicId() async throws {
        // Arrange
        let date = Date()
        let expectedId = ChildPoints.deterministicId(childId: testChild.id, date: date)

        let childPoints = ChildPoints(
            id: expectedId,
            childId: testChild.id,
            date: date,
            pointsEarned: 10,
            pointsDeducted: 0,
            bonusPoints: 0
        )

        // Act
        let saved = try await sut.saveChildPoints(childPoints)

        // Assert
        XCTAssertEqual(saved.id, expectedId)
    }

    func testFetchChildPoints_WithExistingRecord_ReturnsRecord() async throws {
        // Arrange
        let date = Date()
        let childPoints = ChildPoints(
            childId: testChild.id,
            date: date,
            pointsEarned: 15,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await sut.saveChildPoints(childPoints)

        // Act
        let fetched = try await sut.fetchChildPoints(for: testChild.id, date: date)

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.childId, testChild.id)
        XCTAssertEqual(fetched?.pointsEarned, 15)
    }

    func testFetchChildPoints_WithNoRecord_ReturnsNil() async throws {
        // Act
        let fetched = try await sut.fetchChildPoints(for: testChild.id, date: Date())

        // Assert
        XCTAssertNil(fetched, "Should return nil when no record exists")
    }

    func testFetchChildPoints_DateRange_ReturnsMultipleRecords() async throws {
        // Arrange: Create points for 3 consecutive days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let points1 = ChildPoints(childId: testChild.id, date: twoDaysAgo, pointsEarned: 10)
        let points2 = ChildPoints(childId: testChild.id, date: yesterday, pointsEarned: 20)
        let points3 = ChildPoints(childId: testChild.id, date: today, pointsEarned: 30)

        _ = try await sut.saveChildPoints(points1)
        _ = try await sut.saveChildPoints(points2)
        _ = try await sut.saveChildPoints(points3)

        // Act
        let weekStart = calendar.date(byAdding: .day, value: -7, to: today)!
        let dateRange = DateInterval(start: weekStart, end: today.addingTimeInterval(86400))
        let fetched = try await sut.fetchChildPoints(for: testChild.id, dateRange: dateRange)

        // Assert
        XCTAssertEqual(fetched.count, 3)
        XCTAssertTrue(fetched.contains { $0.pointsEarned == 10 })
        XCTAssertTrue(fetched.contains { $0.pointsEarned == 20 })
        XCTAssertTrue(fetched.contains { $0.pointsEarned == 30 })
    }

    func testFetchChildPoints_OnlyReturnsForSpecificChild() async throws {
        // Arrange: Create another child with points
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let testChildPoints = ChildPoints(childId: testChild.id, date: Date(), pointsEarned: 10)
        let otherChildPoints = ChildPoints(childId: otherChild.id, date: Date(), pointsEarned: 20)

        _ = try await sut.saveChildPoints(testChildPoints)
        _ = try await sut.saveChildPoints(otherChildPoints)

        // Act
        let fetched = try await sut.fetchChildPoints(for: testChild.id, date: Date())

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.childId, testChild.id)
        XCTAssertEqual(fetched?.pointsEarned, 10)
    }

    // MARK: - PointsTransaction Tests

    func testCreateTransaction_WithValidData_SavesSuccessfully() async throws {
        // Arrange
        let transaction = PointsTransaction(
            childId: testChild.id,
            activityId: UUID(),
            amount: 10,
            reason: .activityComplete,
            timestamp: Date()
        )

        // Act
        let created = try await sut.createTransaction(transaction)

        // Assert
        XCTAssertEqual(created.id, transaction.id)
        XCTAssertEqual(created.childId, testChild.id)
        XCTAssertEqual(created.amount, 10)
        XCTAssertEqual(created.reason, .activityComplete)
        XCTAssertTrue(created.isPositive)
    }

    func testCreateTransaction_NegativeAmount_SavesCorrectly() async throws {
        // Arrange
        let transaction = PointsTransaction(
            childId: testChild.id,
            activityId: nil,
            amount: -5,
            reason: .activityIncomplete,
            timestamp: Date()
        )

        // Act
        let created = try await sut.createTransaction(transaction)

        // Assert
        XCTAssertEqual(created.amount, -5)
        XCTAssertFalse(created.isPositive)
        XCTAssertEqual(created.absoluteAmount, 5)
    }

    func testCreateTransaction_WithoutActivityId_SavesSuccessfully() async throws {
        // Arrange
        let transaction = PointsTransaction(
            childId: testChild.id,
            activityId: nil,
            amount: 20,
            reason: .achievementUnlock,
            timestamp: Date()
        )

        // Act
        let created = try await sut.createTransaction(transaction)

        // Assert
        XCTAssertNil(created.activityId)
        XCTAssertEqual(created.amount, 20)
    }

    func testFetchTransactions_WithLimit_ReturnsCorrectNumber() async throws {
        // Arrange: Create 5 transactions
        for i in 1...5 {
            let transaction = PointsTransaction(
                childId: testChild.id,
                amount: i * 10,
                reason: .activityComplete,
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 60))
            )
            _ = try await sut.createTransaction(transaction)
        }

        // Act
        let transactions = try await sut.fetchTransactions(for: testChild.id, limit: 3)

        // Assert
        XCTAssertEqual(transactions.count, 3)
        // Should be ordered by most recent first
        XCTAssertEqual(transactions[0].amount, 10) // Most recent
        XCTAssertEqual(transactions[1].amount, 20)
        XCTAssertEqual(transactions[2].amount, 30)
    }

    func testFetchTransactions_OrdersByMostRecentFirst() async throws {
        // Arrange
        let old = PointsTransaction(
            childId: testChild.id,
            amount: 10,
            reason: .activityComplete,
            timestamp: Date().addingTimeInterval(-3600)
        )
        let recent = PointsTransaction(
            childId: testChild.id,
            amount: 20,
            reason: .earlyFinishBonus,
            timestamp: Date()
        )

        _ = try await sut.createTransaction(old)
        _ = try await sut.createTransaction(recent)

        // Act
        let transactions = try await sut.fetchTransactions(for: testChild.id, limit: 10)

        // Assert
        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(transactions[0].amount, 20, "Most recent should be first")
        XCTAssertEqual(transactions[1].amount, 10)
    }

    func testFetchTransactions_OnlyReturnsForSpecificChild() async throws {
        // Arrange
        let otherChild = Child(name: "Other Child", age: 8)
        try createChildEntity(otherChild)

        let testChildTx = PointsTransaction(
            childId: testChild.id,
            amount: 10,
            reason: .activityComplete
        )
        let otherChildTx = PointsTransaction(
            childId: otherChild.id,
            amount: 20,
            reason: .activityComplete
        )

        _ = try await sut.createTransaction(testChildTx)
        _ = try await sut.createTransaction(otherChildTx)

        // Act
        let transactions = try await sut.fetchTransactions(for: testChild.id, limit: 10)

        // Assert
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].childId, testChild.id)
        XCTAssertEqual(transactions[0].amount, 10)
    }

    func testFetchTransactions_DateRange_ReturnsCorrectTransactions() async throws {
        // Arrange
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let tx1 = PointsTransaction(childId: testChild.id, amount: 10, reason: .activityComplete, timestamp: twoDaysAgo)
        let tx2 = PointsTransaction(childId: testChild.id, amount: 20, reason: .earlyFinishBonus, timestamp: yesterday)
        let tx3 = PointsTransaction(childId: testChild.id, amount: 30, reason: .beatAverageBonus, timestamp: today)

        _ = try await sut.createTransaction(tx1)
        _ = try await sut.createTransaction(tx2)
        _ = try await sut.createTransaction(tx3)

        // Act: Fetch only yesterday's transactions
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
        let dateRange = DateInterval(start: startOfYesterday, end: endOfYesterday)
        let transactions = try await sut.fetchTransactions(for: testChild.id, dateRange: dateRange)

        // Assert
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].amount, 20)
    }

    func testFetchTransactions_AllReasonsTypes_SavedCorrectly() async throws {
        // Arrange: Create transaction for each reason type
        let reasons: [PointsReason] = [
            .activityComplete,
            .activityIncomplete,
            .earlyFinishBonus,
            .beatAverageBonus,
            .threeStrikePenalty,
            .achievementUnlock,
            .weeklyReward
        ]

        for (index, reason) in reasons.enumerated() {
            let transaction = PointsTransaction(
                childId: testChild.id,
                amount: index + 1,
                reason: reason,
                timestamp: Date().addingTimeInterval(TimeInterval(-index))
            )
            _ = try await sut.createTransaction(transaction)
        }

        // Act
        let transactions = try await sut.fetchTransactions(for: testChild.id, limit: 20)

        // Assert
        XCTAssertEqual(transactions.count, 7)
        let savedReasons = Set(transactions.map { $0.reason })
        XCTAssertEqual(savedReasons.count, 7, "All reason types should be saved")
        for reason in reasons {
            XCTAssertTrue(savedReasons.contains(reason))
        }
    }

    // MARK: - Integration Tests

    func testCompletePointsWorkflow_AwardAndTrack() async throws {
        // Test complete workflow: award points, create transaction, verify both

        // 1. Create initial ChildPoints for today
        let today = Date()
        let initialPoints = ChildPoints(childId: testChild.id, date: today, pointsEarned: 0)
        _ = try await sut.saveChildPoints(initialPoints)

        // 2. Award points for activity
        let transaction1 = PointsTransaction(
            childId: testChild.id,
            amount: 10,
            reason: .activityComplete,
            timestamp: today
        )
        _ = try await sut.createTransaction(transaction1)

        // 3. Update ChildPoints
        let updated1 = ChildPoints(
            id: initialPoints.id,
            childId: testChild.id,
            date: today,
            pointsEarned: 10,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        _ = try await sut.saveChildPoints(updated1)

        // 4. Award bonus points
        let transaction2 = PointsTransaction(
            childId: testChild.id,
            amount: 5,
            reason: .earlyFinishBonus,
            timestamp: today
        )
        _ = try await sut.createTransaction(transaction2)

        // 5. Update ChildPoints with bonus
        let updated2 = ChildPoints(
            id: initialPoints.id,
            childId: testChild.id,
            date: today,
            pointsEarned: 10,
            pointsDeducted: 0,
            bonusPoints: 5
        )
        let final = try await sut.saveChildPoints(updated2)

        // Assert final state
        XCTAssertEqual(final.pointsEarned, 10)
        XCTAssertEqual(final.bonusPoints, 5)
        XCTAssertEqual(final.totalPoints, 15)

        // Verify transaction history
        let transactions = try await sut.fetchTransactions(for: testChild.id, limit: 10)
        XCTAssertEqual(transactions.count, 2)
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
