//
//  RewardsServiceTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for RewardsService - Weekly reward tracking, tier calculation, and redemption
final class RewardsServiceTests: XCTestCase {

    var sut: RewardsService!
    var mockRepository: MockRewardsRepository!
    var testChild: Child!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockRepository = MockRewardsRepository()
        sut = RewardsService(repository: mockRepository)

        // Setup test data
        testChild = Child(name: "Test Child", age: 10)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockRepository = nil
        testChild = nil
        try super.tearDownWithError()
    }

    // MARK: - getCurrentWeekProgress Tests

    func testGetCurrentWeekProgress_WithNoReward_ReturnsZeroProgress() async throws {
        // Arrange
        mockRepository.mockCurrentWeekReward = nil

        // Act
        let progress = try await sut.getCurrentWeekProgress(for: testChild.id)

        // Assert
        XCTAssertEqual(progress.points, 0, "Should return zero points when no reward exists")
        XCTAssertNil(progress.tier, "Should have no tier when no points")
        XCTAssertEqual(progress.nextTier, .bronze, "Next tier should be bronze")
        XCTAssertEqual(progress.pointsToNext, 100, "Should need 100 points to reach bronze")
        XCTAssertEqual(progress.progressPercentage, 0, accuracy: 0.1)
    }

    func testGetCurrentWeekProgress_WithBronzeTier_ReturnsCorrectProgress() async throws {
        // Arrange: 150 points (bronze tier)
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 150,
            tier: .bronze
        )
        mockRepository.mockCurrentWeekReward = reward

        // Act
        let progress = try await sut.getCurrentWeekProgress(for: testChild.id)

        // Assert
        XCTAssertEqual(progress.points, 150)
        XCTAssertEqual(progress.tier, .bronze)
        XCTAssertEqual(progress.nextTier, .silver)
        XCTAssertEqual(progress.pointsToNext, 100, "Should need 100 more points to reach silver (250)")
        XCTAssertTrue(progress.hasTier)
        XCTAssertFalse(progress.isMaxTier)
    }

    func testGetCurrentWeekProgress_WithPlatinumTier_ReturnsMaxTier() async throws {
        // Arrange: 1200 points (platinum tier)
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 1200,
            tier: .platinum
        )
        mockRepository.mockCurrentWeekReward = reward

        // Act
        let progress = try await sut.getCurrentWeekProgress(for: testChild.id)

        // Assert
        XCTAssertEqual(progress.points, 1200)
        XCTAssertEqual(progress.tier, .platinum)
        XCTAssertNil(progress.nextTier, "Platinum is the max tier")
        XCTAssertEqual(progress.pointsToNext, 0, "No points needed at max tier")
        XCTAssertTrue(progress.isMaxTier)
    }

    func testGetCurrentWeekProgress_BelowBronze_ShowsProgressToBronze() async throws {
        // Arrange: 75 points (below bronze)
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 75,
            tier: nil
        )
        mockRepository.mockCurrentWeekReward = reward

        // Act
        let progress = try await sut.getCurrentWeekProgress(for: testChild.id)

        // Assert
        XCTAssertEqual(progress.points, 75)
        XCTAssertNil(progress.tier)
        XCTAssertEqual(progress.nextTier, .bronze)
        XCTAssertEqual(progress.pointsToNext, 25, "Should need 25 more points to reach bronze")
        XCTAssertEqual(progress.progressPercentage, 75, accuracy: 0.1, "75% progress to bronze")
    }

    // MARK: - getWeeklyRewards Tests

    func testGetWeeklyRewards_WithNoRewards_ReturnsEmptyArray() async throws {
        // Arrange
        mockRepository.mockRewards = []

        // Act
        let rewards = try await sut.getWeeklyRewards(for: testChild.id)

        // Assert
        XCTAssertTrue(rewards.isEmpty, "Should return empty array when no rewards exist")
    }

    func testGetWeeklyRewards_WithMultipleRewards_ReturnsAllSorted() async throws {
        // Arrange: Create multiple weekly rewards
        let calendar = Calendar.current
        let today = Date()

        let week1 = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1)

        let week2 = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2)

        let (start3, end3) = WeeklyReward.currentWeekDates()

        let rewards = [
            WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 200, tier: .silver),
            WeeklyReward(childId: testChild.id, weekStartDate: start2, weekEndDate: end2, totalPoints: 500, tier: .gold),
            WeeklyReward(childId: testChild.id, weekStartDate: start3, weekEndDate: end3, totalPoints: 150, tier: .bronze)
        ]
        mockRepository.mockRewards = rewards

        // Act
        let fetched = try await sut.getWeeklyRewards(for: testChild.id)

        // Assert
        XCTAssertEqual(fetched.count, 3)
        // Should be sorted by date (most recent first)
        XCTAssertEqual(fetched[0].totalPoints, 150) // Current week
        XCTAssertEqual(fetched[1].totalPoints, 500) // Last week
        XCTAssertEqual(fetched[2].totalPoints, 200) // Two weeks ago
    }

    // MARK: - getWeeklyRewards (Date Range) Tests

    func testGetWeeklyRewards_WithDateRange_ReturnsOnlyMatching() async throws {
        // Arrange
        let calendar = Calendar.current
        let today = Date()

        let week1 = calendar.date(byAdding: .day, value: -28, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1)

        let week2 = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2)

        let rewards = [
            WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 100),
            WeeklyReward(childId: testChild.id, weekStartDate: start2, weekEndDate: end2, totalPoints: 200)
        ]
        mockRepository.mockRewards = rewards

        // Act: Query last 20 days (should only return week2)
        let rangeStart = calendar.date(byAdding: .day, value: -20, to: today)!
        let rangeEnd = today
        let fetched = try await sut.getWeeklyRewards(for: testChild.id, from: rangeStart, to: rangeEnd)

        // Assert
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].totalPoints, 200)
    }

    // MARK: - redeemReward Tests

    func testRedeemReward_WithUnredeemedReward_MarksAsRedeemed() async throws {
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
        mockRepository.mockRewards = [reward]

        // Act
        try await sut.redeemReward(reward.id)

        // Assert
        XCTAssertEqual(mockRepository.updateCallCount, 1, "Should call update once")
        let updated = mockRepository.lastUpdatedReward
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated!.isRedeemed)
        XCTAssertNotNil(updated!.redeemedDate)
    }

    func testRedeemReward_WithAlreadyRedeemedReward_ThrowsError() async throws {
        // Arrange: Create already redeemed reward
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let reward = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 500,
            tier: .gold,
            isRedeemed: true,
            redeemedDate: Date()
        )
        mockRepository.mockRewards = [reward]

        // Act & Assert
        do {
            try await sut.redeemReward(reward.id)
            XCTFail("Should throw error when redeeming already redeemed reward")
        } catch RewardsServiceError.alreadyRedeemed {
            // Expected error
        }
    }

    func testRedeemReward_WithNonExistentReward_ThrowsError() async throws {
        // Arrange
        mockRepository.mockRewards = []
        let nonExistentId = UUID()

        // Act & Assert
        do {
            try await sut.redeemReward(nonExistentId)
            XCTFail("Should throw error when reward not found")
        } catch RewardsServiceError.rewardNotFound {
            // Expected error
        }
    }

    // MARK: - calculateTier Tests

    func testCalculateTier_BelowBronze_ReturnsNil() {
        // Arrange: 99 points (below bronze)
        let points = 99

        // Act
        let tier = sut.calculateTier(for: points)

        // Assert
        XCTAssertNil(tier, "Should return nil for points below bronze threshold")
    }

    func testCalculateTier_BronzeRange_ReturnsBronze() {
        // Arrange: 100-249 points
        let tier100 = sut.calculateTier(for: 100)
        let tier150 = sut.calculateTier(for: 150)
        let tier249 = sut.calculateTier(for: 249)

        // Assert
        XCTAssertEqual(tier100, .bronze)
        XCTAssertEqual(tier150, .bronze)
        XCTAssertEqual(tier249, .bronze)
    }

    func testCalculateTier_SilverRange_ReturnsSilver() {
        // Arrange: 250-499 points
        let tier250 = sut.calculateTier(for: 250)
        let tier300 = sut.calculateTier(for: 300)
        let tier499 = sut.calculateTier(for: 499)

        // Assert
        XCTAssertEqual(tier250, .silver)
        XCTAssertEqual(tier300, .silver)
        XCTAssertEqual(tier499, .silver)
    }

    func testCalculateTier_GoldRange_ReturnsGold() {
        // Arrange: 500-999 points
        let tier500 = sut.calculateTier(for: 500)
        let tier750 = sut.calculateTier(for: 750)
        let tier999 = sut.calculateTier(for: 999)

        // Assert
        XCTAssertEqual(tier500, .gold)
        XCTAssertEqual(tier750, .gold)
        XCTAssertEqual(tier999, .gold)
    }

    func testCalculateTier_PlatinumRange_ReturnsPlatinum() {
        // Arrange: 1000+ points
        let tier1000 = sut.calculateTier(for: 1000)
        let tier1500 = sut.calculateTier(for: 1500)
        let tier5000 = sut.calculateTier(for: 5000)

        // Assert
        XCTAssertEqual(tier1000, .platinum)
        XCTAssertEqual(tier1500, .platinum)
        XCTAssertEqual(tier5000, .platinum)
    }

    // MARK: - addPoints Tests

    func testAddPoints_ToNewWeek_CreatesRewardWithPoints() async throws {
        // Arrange: No existing reward
        mockRepository.mockCurrentWeekReward = nil

        // Act
        let result = try await sut.addPoints(50, for: testChild.id)

        // Assert
        XCTAssertEqual(result.totalPoints, 50)
        XCTAssertNil(result.tier, "50 points should not reach bronze tier")
        XCTAssertEqual(mockRepository.createCallCount, 1, "Should create new reward")
    }

    func testAddPoints_ToExistingReward_UpdatesPoints() async throws {
        // Arrange: Existing reward with 80 points
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let existing = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 80,
            tier: nil
        )
        mockRepository.mockCurrentWeekReward = existing

        // Act: Add 30 more points (total: 110)
        let result = try await sut.addPoints(30, for: testChild.id)

        // Assert
        XCTAssertEqual(result.totalPoints, 110)
        XCTAssertEqual(result.tier, .bronze, "110 points should reach bronze tier")
        XCTAssertEqual(mockRepository.updateCallCount, 1, "Should update existing reward")
    }

    func testAddPoints_CausesTierUpgrade_UpdatesTierCorrectly() async throws {
        // Arrange: Existing bronze reward with 200 points
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let existing = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 200,
            tier: .silver
        )
        mockRepository.mockCurrentWeekReward = existing

        // Act: Add 350 more points (total: 550)
        let result = try await sut.addPoints(350, for: testChild.id)

        // Assert
        XCTAssertEqual(result.totalPoints, 550)
        XCTAssertEqual(result.tier, .gold, "550 points should upgrade to gold tier")
    }

    // MARK: - getRewardHistory Tests

    func testGetRewardHistory_WithNoRewards_ReturnsZeroStats() async throws {
        // Arrange
        mockRepository.mockRewards = []

        // Act
        let history = try await sut.getRewardHistory(for: testChild.id)

        // Assert
        XCTAssertEqual(history.totalPointsAllTime, 0)
        XCTAssertEqual(history.totalWeeksCompleted, 0)
        XCTAssertEqual(history.bronzeTiersEarned, 0)
        XCTAssertEqual(history.silverTiersEarned, 0)
        XCTAssertEqual(history.goldTiersEarned, 0)
        XCTAssertEqual(history.platinumTiersEarned, 0)
        XCTAssertEqual(history.currentStreak, 0)
        XCTAssertEqual(history.longestStreak, 0)
    }

    func testGetRewardHistory_WithMultipleTiers_AggregatesCorrectly() async throws {
        // Arrange: Create rewards with various tiers
        let calendar = Calendar.current
        let today = Date()

        let week1 = calendar.date(byAdding: .day, value: -21, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1)

        let week2 = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2)

        let week3 = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start3, end3) = WeeklyReward.weekDates(for: week3)

        let rewards = [
            WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 150, tier: .bronze),
            WeeklyReward(childId: testChild.id, weekStartDate: start2, weekEndDate: end2, totalPoints: 300, tier: .silver),
            WeeklyReward(childId: testChild.id, weekStartDate: start3, weekEndDate: end3, totalPoints: 600, tier: .gold)
        ]
        mockRepository.mockRewards = rewards

        // Act
        let history = try await sut.getRewardHistory(for: testChild.id)

        // Assert
        XCTAssertEqual(history.totalPointsAllTime, 1050, "Should sum all points")
        XCTAssertEqual(history.totalWeeksCompleted, 3)
        XCTAssertEqual(history.bronzeTiersEarned, 1)
        XCTAssertEqual(history.silverTiersEarned, 1)
        XCTAssertEqual(history.goldTiersEarned, 1)
        XCTAssertEqual(history.platinumTiersEarned, 0)
        XCTAssertEqual(history.highestTierEarned, .gold)
    }

    func testGetRewardHistory_CalculatesStreak_Correctly() async throws {
        // Arrange: Create consecutive weekly rewards
        let calendar = Calendar.current
        let today = Date()

        let week1 = calendar.date(byAdding: .day, value: -21, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1)

        let week2 = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2)

        let week3 = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start3, end3) = WeeklyReward.weekDates(for: week3)

        let (start4, end4) = WeeklyReward.currentWeekDates()

        let rewards = [
            WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 150, tier: .bronze),
            WeeklyReward(childId: testChild.id, weekStartDate: start2, weekEndDate: end2, totalPoints: 200, tier: .silver),
            WeeklyReward(childId: testChild.id, weekStartDate: start3, weekEndDate: end3, totalPoints: 250, tier: .silver),
            WeeklyReward(childId: testChild.id, weekStartDate: start4, weekEndDate: end4, totalPoints: 100, tier: .bronze)
        ]
        mockRepository.mockRewards = rewards

        // Act
        let history = try await sut.getRewardHistory(for: testChild.id)

        // Assert
        XCTAssertEqual(history.currentStreak, 4, "Should have 4-week current streak")
        XCTAssertEqual(history.longestStreak, 4, "Should have 4-week longest streak")
    }

    func testGetRewardHistory_WithBrokenStreak_CalculatesCorrectly() async throws {
        // Arrange: Create rewards with a gap
        let calendar = Calendar.current
        let today = Date()

        let week1 = calendar.date(byAdding: .day, value: -28, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1)

        // Skip week 2 (no reward)

        let week3 = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start3, end3) = WeeklyReward.weekDates(for: week3)

        let week4 = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start4, end4) = WeeklyReward.weekDates(for: week4)

        let (start5, end5) = WeeklyReward.currentWeekDates()

        let rewards = [
            WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 150, tier: .bronze),
            // Gap here (week 2)
            WeeklyReward(childId: testChild.id, weekStartDate: start3, weekEndDate: end3, totalPoints: 200, tier: .silver),
            WeeklyReward(childId: testChild.id, weekStartDate: start4, weekEndDate: end4, totalPoints: 300, tier: .silver),
            WeeklyReward(childId: testChild.id, weekStartDate: start5, weekEndDate: end5, totalPoints: 100, tier: .bronze)
        ]
        mockRepository.mockRewards = rewards

        // Act
        let history = try await sut.getRewardHistory(for: testChild.id)

        // Assert
        XCTAssertEqual(history.currentStreak, 3, "Should have 3-week current streak")
        XCTAssertEqual(history.longestStreak, 3, "Longest streak should be 3 weeks")
    }

    // MARK: - getCurrentWeekReward Tests

    func testGetCurrentWeekReward_WithNoExisting_CreatesNewReward() async throws {
        // Arrange
        mockRepository.mockCurrentWeekReward = nil

        // Act
        let reward = try await sut.getCurrentWeekReward(for: testChild.id)

        // Assert
        XCTAssertNotNil(reward)
        XCTAssertEqual(reward.childId, testChild.id)
        XCTAssertEqual(reward.totalPoints, 0)
        XCTAssertNil(reward.tier)
        XCTAssertFalse(reward.isRedeemed)
        XCTAssertTrue(reward.isCurrentWeek)
        XCTAssertEqual(mockRepository.createCallCount, 1)
    }

    func testGetCurrentWeekReward_WithExisting_ReturnsExisting() async throws {
        // Arrange
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()
        let existing = WeeklyReward(
            childId: testChild.id,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalPoints: 200,
            tier: .silver
        )
        mockRepository.mockCurrentWeekReward = existing

        // Act
        let reward = try await sut.getCurrentWeekReward(for: testChild.id)

        // Assert
        XCTAssertEqual(reward.id, existing.id)
        XCTAssertEqual(reward.totalPoints, 200)
        XCTAssertEqual(reward.tier, .silver)
        XCTAssertEqual(mockRepository.createCallCount, 0, "Should not create new reward")
    }

    // MARK: - getUnredeemedRewards Tests

    func testGetUnredeemedRewards_WithNoUnredeemed_ReturnsEmptyArray() async throws {
        // Arrange: Only redeemed rewards
        let (start, end) = WeeklyReward.currentWeekDates()
        let redeemed = WeeklyReward(
            childId: testChild.id,
            weekStartDate: start,
            weekEndDate: end,
            totalPoints: 500,
            tier: .gold,
            isRedeemed: true,
            redeemedDate: Date()
        )
        mockRepository.mockRewards = [redeemed]

        // Act
        let unredeemed = try await sut.getUnredeemedRewards(for: testChild.id)

        // Assert
        XCTAssertTrue(unredeemed.isEmpty)
    }

    func testGetUnredeemedRewards_WithUnredeemed_ReturnsOnlyWithTiers() async throws {
        // Arrange: Mix of unredeemed rewards with and without tiers
        let calendar = Calendar.current
        let today = Date()

        let week1 = calendar.date(byAdding: .day, value: -14, to: today)!
        let (start1, end1) = WeeklyReward.weekDates(for: week1)

        let week2 = calendar.date(byAdding: .day, value: -7, to: today)!
        let (start2, end2) = WeeklyReward.weekDates(for: week2)

        let (start3, end3) = WeeklyReward.currentWeekDates()

        let rewards = [
            WeeklyReward(childId: testChild.id, weekStartDate: start1, weekEndDate: end1, totalPoints: 50, tier: nil, isRedeemed: false),
            WeeklyReward(childId: testChild.id, weekStartDate: start2, weekEndDate: end2, totalPoints: 300, tier: .silver, isRedeemed: false),
            WeeklyReward(childId: testChild.id, weekStartDate: start3, weekEndDate: end3, totalPoints: 500, tier: .gold, isRedeemed: false)
        ]
        mockRepository.mockRewards = rewards

        // Act
        let unredeemed = try await sut.getUnredeemedRewards(for: testChild.id)

        // Assert
        XCTAssertEqual(unredeemed.count, 2, "Should return only unredeemed rewards with tiers")
        XCTAssertTrue(unredeemed.allSatisfy { !$0.isRedeemed && $0.tier != nil })
    }
}

// MARK: - Mock Repository

class MockRewardsRepository: RewardsRepositoryProtocol {
    var mockRewards: [WeeklyReward] = []
    var mockCurrentWeekReward: WeeklyReward?
    var lastUpdatedReward: WeeklyReward?
    var createCallCount = 0
    var updateCallCount = 0

    func create(_ reward: WeeklyReward) async throws -> WeeklyReward {
        createCallCount += 1
        mockRewards.append(reward)
        return reward
    }

    func fetchAll(for childId: UUID) async throws -> [WeeklyReward] {
        return mockRewards
            .filter { $0.childId == childId }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }

    func fetchRewards(for childId: UUID, from startDate: Date, to endDate: Date) async throws -> [WeeklyReward] {
        return mockRewards
            .filter { $0.childId == childId && $0.weekStartDate >= startDate && $0.weekStartDate <= endDate }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }

    func fetchReward(for childId: UUID, weekStartDate: Date) async throws -> WeeklyReward? {
        // First check explicit mock, then check created rewards
        if let mocked = mockCurrentWeekReward {
            return mocked
        }
        // Search mockRewards for matching week
        let calendar = Calendar.current
        return mockRewards.first { reward in
            reward.childId == childId &&
            calendar.isDate(reward.weekStartDate, inSameDayAs: weekStartDate)
        }
    }

    func fetch(by id: UUID) async throws -> WeeklyReward? {
        return mockRewards.first { $0.id == id }
    }

    func update(_ reward: WeeklyReward) async throws -> WeeklyReward {
        updateCallCount += 1
        lastUpdatedReward = reward
        if let index = mockRewards.firstIndex(where: { $0.id == reward.id }) {
            mockRewards[index] = reward
        }
        return reward
    }

    func delete(_ rewardId: UUID) async throws {
        mockRewards.removeAll { $0.id == rewardId }
    }

    func fetchUnredeemed(for childId: UUID) async throws -> [WeeklyReward] {
        return mockRewards
            .filter { $0.childId == childId && !$0.isRedeemed }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }

    func fetchWithTiers(for childId: UUID) async throws -> [WeeklyReward] {
        return mockRewards
            .filter { $0.childId == childId && $0.tier != nil }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }
}

// Note: RewardsServiceError is defined in the main target (RewardsService.swift)
