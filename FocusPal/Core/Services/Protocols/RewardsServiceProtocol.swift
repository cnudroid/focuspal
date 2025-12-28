//
//  RewardsServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Progress information for the current week's rewards
struct WeeklyRewardProgress: Equatable {
    let points: Int
    let tier: RewardTier?
    let nextTier: RewardTier?
    let pointsToNext: Int
    let progressPercentage: Double
    let weekStartDate: Date
    let weekEndDate: Date

    /// Whether any tier has been achieved
    var hasTier: Bool {
        tier != nil
    }

    /// Whether the maximum tier (platinum) has been reached
    var isMaxTier: Bool {
        tier == .platinum
    }
}

/// Protocol defining the rewards service interface.
/// Manages weekly reward tracking, tier calculation, and reward redemption.
protocol RewardsServiceProtocol {
    /// Get the current week's reward progress for a child
    /// - Parameter childId: The child's UUID
    /// - Returns: Progress information including points, current tier, next tier, and points needed
    /// - Throws: If the child cannot be found or data cannot be fetched
    func getCurrentWeekProgress(for childId: UUID) async throws -> WeeklyRewardProgress

    /// Get all weekly rewards for a child (historical data)
    /// - Parameter childId: The child's UUID
    /// - Returns: Array of weekly rewards sorted by date (most recent first)
    /// - Throws: If the child cannot be found or data cannot be fetched
    func getWeeklyRewards(for childId: UUID) async throws -> [WeeklyReward]

    /// Get weekly rewards within a date range
    /// - Parameters:
    ///   - childId: The child's UUID
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of weekly rewards within the range
    /// - Throws: If data cannot be fetched
    func getWeeklyRewards(for childId: UUID, from startDate: Date, to endDate: Date) async throws -> [WeeklyReward]

    /// Redeem a weekly reward
    /// - Parameter rewardId: The reward's UUID
    /// - Throws: If the reward cannot be found or has already been redeemed
    func redeemReward(_ rewardId: UUID) async throws

    /// Calculate which tier corresponds to a given point total
    /// - Parameter points: The number of points
    /// - Returns: The highest tier achieved, or nil if below bronze threshold
    func calculateTier(for points: Int) -> RewardTier?

    /// Add points to the current week's reward for a child
    /// - Parameters:
    ///   - points: Number of points to add
    ///   - childId: The child's UUID
    /// - Returns: Updated weekly reward with new points and potentially new tier
    /// - Throws: If the child cannot be found or data cannot be saved
    @discardableResult
    func addPoints(_ points: Int, for childId: UUID) async throws -> WeeklyReward

    /// Get the reward history (all-time statistics) for a child
    /// - Parameter childId: The child's UUID
    /// - Returns: Aggregate reward history
    /// - Throws: If the child cannot be found or data cannot be fetched
    func getRewardHistory(for childId: UUID) async throws -> RewardHistory

    /// Get or create the current week's reward for a child
    /// - Parameter childId: The child's UUID
    /// - Returns: The current week's reward (created if it doesn't exist)
    /// - Throws: If the child cannot be found or data cannot be saved
    func getCurrentWeekReward(for childId: UUID) async throws -> WeeklyReward

    /// Check if a child has any unredeemed rewards
    /// - Parameter childId: The child's UUID
    /// - Returns: Array of unredeemed rewards with tiers
    /// - Throws: If data cannot be fetched
    func getUnredeemedRewards(for childId: UUID) async throws -> [WeeklyReward]
}

// MARK: - Default Implementations

extension RewardsServiceProtocol {
    /// Calculate which tier corresponds to a given point total
    /// Default implementation using RewardTier.tier(for:)
    func calculateTier(for points: Int) -> RewardTier? {
        RewardTier.tier(for: points)
    }
}
