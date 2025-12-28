//
//  RewardsService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Service errors specific to rewards operations
enum RewardsServiceError: Error, LocalizedError {
    case rewardNotFound
    case alreadyRedeemed
    case invalidPoints

    var errorDescription: String? {
        switch self {
        case .rewardNotFound: return "Reward not found"
        case .alreadyRedeemed: return "Reward has already been redeemed"
        case .invalidPoints: return "Points value must be positive"
        }
    }
}

/// Concrete implementation of the rewards service.
/// Manages weekly reward tracking, tier calculation, and redemption.
class RewardsService: RewardsServiceProtocol {

    // MARK: - Properties

    private let repository: RewardsRepositoryProtocol

    // MARK: - Initialization

    init(repository: RewardsRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - RewardsServiceProtocol

    func getCurrentWeekProgress(for childId: UUID) async throws -> WeeklyRewardProgress {
        let reward = try await getCurrentWeekReward(for: childId)

        let tier = reward.tier
        let nextTier = reward.nextTier
        let pointsToNext = reward.pointsToNextTier ?? 0
        let progress = reward.progressToNextTier

        return WeeklyRewardProgress(
            points: reward.totalPoints,
            tier: tier,
            nextTier: nextTier,
            pointsToNext: pointsToNext,
            progressPercentage: progress,
            weekStartDate: reward.weekStartDate,
            weekEndDate: reward.weekEndDate
        )
    }

    func getWeeklyRewards(for childId: UUID) async throws -> [WeeklyReward] {
        return try await repository.fetchAll(for: childId)
    }

    func getWeeklyRewards(for childId: UUID, from startDate: Date, to endDate: Date) async throws -> [WeeklyReward] {
        return try await repository.fetchRewards(for: childId, from: startDate, to: endDate)
    }

    func redeemReward(_ rewardId: UUID) async throws {
        // Fetch the reward
        guard let reward = try await repository.fetch(by: rewardId) else {
            throw RewardsServiceError.rewardNotFound
        }

        // Check if already redeemed
        if reward.isRedeemed {
            throw RewardsServiceError.alreadyRedeemed
        }

        // Update reward as redeemed
        var updated = reward
        updated.isRedeemed = true
        updated.redeemedDate = Date()

        try await repository.update(updated)
    }

    func calculateTier(for points: Int) -> RewardTier? {
        return RewardTier.tier(for: points)
    }

    func addPoints(_ points: Int, for childId: UUID) async throws -> WeeklyReward {
        guard points > 0 else {
            throw RewardsServiceError.invalidPoints
        }

        // Get or create current week's reward
        var reward = try await getCurrentWeekReward(for: childId)

        // Add points
        reward.totalPoints += points

        // Recalculate tier
        reward.tier = calculateTier(for: reward.totalPoints)

        // Update or create in repository
        if let existing = try await repository.fetchReward(for: childId, weekStartDate: reward.weekStartDate) {
            // Update existing
            var updated = existing
            updated.totalPoints = reward.totalPoints
            updated.tier = reward.tier
            return try await repository.update(updated)
        } else {
            // Create new
            return try await repository.create(reward)
        }
    }

    func getRewardHistory(for childId: UUID) async throws -> RewardHistory {
        let rewards = try await repository.fetchAll(for: childId)

        // Calculate total points
        let totalPoints = rewards.reduce(0) { $0 + $1.totalPoints }

        // Count rewards with tiers (completed weeks)
        let withTiers = rewards.filter { $0.tier != nil }
        let totalWeeks = withTiers.count

        // Count tier achievements
        let bronzeCount = rewards.filter { $0.tier == .bronze }.count
        let silverCount = rewards.filter { $0.tier == .silver }.count
        let goldCount = rewards.filter { $0.tier == .gold }.count
        let platinumCount = rewards.filter { $0.tier == .platinum }.count

        // Calculate streaks
        let (currentStreak, longestStreak) = calculateStreaks(from: rewards)

        // Find last week with tier
        let lastWeekWithTier = withTiers.first?.weekStartDate

        return RewardHistory(
            childId: childId,
            totalPointsAllTime: totalPoints,
            totalWeeksCompleted: totalWeeks,
            bronzeTiersEarned: bronzeCount,
            silverTiersEarned: silverCount,
            goldTiersEarned: goldCount,
            platinumTiersEarned: platinumCount,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            lastWeekWithTier: lastWeekWithTier
        )
    }

    func getCurrentWeekReward(for childId: UUID) async throws -> WeeklyReward {
        let (weekStart, weekEnd) = WeeklyReward.currentWeekDates()

        // Try to fetch existing reward for current week
        if let existing = try await repository.fetchReward(for: childId, weekStartDate: weekStart) {
            return existing
        }

        // Create new reward for current week
        let newReward = WeeklyReward.forCurrentWeek(childId: childId)
        return try await repository.create(newReward)
    }

    func getUnredeemedRewards(for childId: UUID) async throws -> [WeeklyReward] {
        let unredeemed = try await repository.fetchUnredeemed(for: childId)
        // Only return rewards that have tiers (earned at least bronze)
        return unredeemed.filter { $0.tier != nil }
    }

    // MARK: - Private Methods

    /// Calculate current and longest streaks from rewards
    /// A streak is consecutive weeks with earned tiers (at least bronze)
    private func calculateStreaks(from rewards: [WeeklyReward]) -> (current: Int, longest: Int) {
        // Filter to only rewards with tiers, sorted by date descending
        let tieredRewards = rewards
            .filter { $0.tier != nil }
            .sorted { $0.weekStartDate > $1.weekStartDate }

        guard !tieredRewards.isEmpty else {
            return (0, 0)
        }

        let calendar = Calendar.current
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var previousWeekStart: Date?

        for reward in tieredRewards {
            if let previous = previousWeekStart {
                // Calculate days between this reward's week and the previous one
                let daysBetween = calendar.dateComponents([.day], from: reward.weekStartDate, to: previous).day ?? 0

                if daysBetween == 7 {
                    // Consecutive weeks (7 days apart)
                    tempStreak += 1
                } else {
                    // Streak broken (gap between weeks)
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                // First reward (most recent)
                tempStreak = 1
            }

            // Track this reward's week for next iteration
            previousWeekStart = reward.weekStartDate
        }

        // Update longest streak with final temp streak
        longestStreak = max(longestStreak, tempStreak)

        // Current streak is valid if most recent reward is from current week or last week
        if let mostRecent = tieredRewards.first {
            let (currentWeekStart, _) = WeeklyReward.currentWeekDates()
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart)!

            if calendar.isDate(mostRecent.weekStartDate, inSameDayAs: currentWeekStart) ||
               calendar.isDate(mostRecent.weekStartDate, inSameDayAs: lastWeekStart) ||
               mostRecent.weekStartDate >= lastWeekStart {
                currentStreak = tempStreak
            } else {
                currentStreak = 0
            }
        }

        return (currentStreak, longestStreak)
    }
}
