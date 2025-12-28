//
//  MockRewardsService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of RewardsService for testing and previews.
class MockRewardsService: RewardsServiceProtocol {

    // MARK: - Mock Data

    var mockRewards: [WeeklyReward] = []
    var mockCurrentWeekReward: WeeklyReward?
    var mockError: Error?

    var getCurrentWeekProgressCallCount = 0
    var addPointsCallCount = 0
    var redeemRewardCallCount = 0

    // MARK: - RewardsServiceProtocol

    func getCurrentWeekProgress(for childId: UUID) async throws -> WeeklyRewardProgress {
        getCurrentWeekProgressCallCount += 1

        if let error = mockError {
            throw error
        }

        let reward = mockCurrentWeekReward ?? WeeklyReward.forCurrentWeek(childId: childId)

        return WeeklyRewardProgress(
            points: reward.totalPoints,
            tier: reward.tier,
            nextTier: reward.nextTier,
            pointsToNext: reward.pointsToNextTier ?? 0,
            progressPercentage: reward.progressToNextTier,
            weekStartDate: reward.weekStartDate,
            weekEndDate: reward.weekEndDate
        )
    }

    func getWeeklyRewards(for childId: UUID) async throws -> [WeeklyReward] {
        if let error = mockError {
            throw error
        }

        return mockRewards
            .filter { $0.childId == childId }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }

    func getWeeklyRewards(for childId: UUID, from startDate: Date, to endDate: Date) async throws -> [WeeklyReward] {
        if let error = mockError {
            throw error
        }

        return mockRewards
            .filter { $0.childId == childId && $0.weekStartDate >= startDate && $0.weekStartDate <= endDate }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }

    func redeemReward(_ rewardId: UUID) async throws {
        redeemRewardCallCount += 1

        if let error = mockError {
            throw error
        }

        if let index = mockRewards.firstIndex(where: { $0.id == rewardId }) {
            mockRewards[index].isRedeemed = true
            mockRewards[index].redeemedDate = Date()
        }
    }

    func calculateTier(for points: Int) -> RewardTier? {
        return RewardTier.tier(for: points)
    }

    func addPoints(_ points: Int, for childId: UUID) async throws -> WeeklyReward {
        addPointsCallCount += 1

        if let error = mockError {
            throw error
        }

        // Get or create current week reward
        var reward = mockCurrentWeekReward ?? WeeklyReward.forCurrentWeek(childId: childId)
        reward.totalPoints += points
        reward.tier = calculateTier(for: reward.totalPoints)

        mockCurrentWeekReward = reward
        return reward
    }

    func getRewardHistory(for childId: UUID) async throws -> RewardHistory {
        if let error = mockError {
            throw error
        }

        let childRewards = mockRewards.filter { $0.childId == childId }

        let totalPoints = childRewards.reduce(0) { $0 + $1.totalPoints }
        let withTiers = childRewards.filter { $0.tier != nil }
        let totalWeeks = withTiers.count

        let bronzeCount = childRewards.filter { $0.tier == .bronze }.count
        let silverCount = childRewards.filter { $0.tier == .silver }.count
        let goldCount = childRewards.filter { $0.tier == .gold }.count
        let platinumCount = childRewards.filter { $0.tier == .platinum }.count

        return RewardHistory(
            childId: childId,
            totalPointsAllTime: totalPoints,
            totalWeeksCompleted: totalWeeks,
            bronzeTiersEarned: bronzeCount,
            silverTiersEarned: silverCount,
            goldTiersEarned: goldCount,
            platinumTiersEarned: platinumCount,
            longestStreak: 0,
            currentStreak: 0,
            lastWeekWithTier: withTiers.first?.weekStartDate
        )
    }

    func getCurrentWeekReward(for childId: UUID) async throws -> WeeklyReward {
        if let error = mockError {
            throw error
        }

        if let existing = mockCurrentWeekReward {
            return existing
        }

        let newReward = WeeklyReward.forCurrentWeek(childId: childId)
        mockCurrentWeekReward = newReward
        return newReward
    }

    func getUnredeemedRewards(for childId: UUID) async throws -> [WeeklyReward] {
        if let error = mockError {
            throw error
        }

        return mockRewards
            .filter { $0.childId == childId && !$0.isRedeemed && $0.tier != nil }
            .sorted { $0.weekStartDate > $1.weekStartDate }
    }

    // MARK: - Helper Methods

    func reset() {
        mockRewards = []
        mockCurrentWeekReward = nil
        mockError = nil
        getCurrentWeekProgressCallCount = 0
        addPointsCallCount = 0
        redeemRewardCallCount = 0
    }

    func addMockReward(_ reward: WeeklyReward) {
        mockRewards.append(reward)
    }

    func setCurrentWeekReward(_ reward: WeeklyReward) {
        mockCurrentWeekReward = reward
    }
}
