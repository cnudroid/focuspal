//
//  RewardsRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the rewards repository interface.
/// Abstracts data access for WeeklyReward entities.
protocol RewardsRepositoryProtocol {
    /// Create a new weekly reward
    func create(_ reward: WeeklyReward) async throws -> WeeklyReward

    /// Fetch all weekly rewards for a child
    func fetchAll(for childId: UUID) async throws -> [WeeklyReward]

    /// Fetch weekly rewards within a date range
    func fetchRewards(for childId: UUID, from startDate: Date, to endDate: Date) async throws -> [WeeklyReward]

    /// Fetch reward for a specific week
    func fetchReward(for childId: UUID, weekStartDate: Date) async throws -> WeeklyReward?

    /// Fetch a reward by ID
    func fetch(by id: UUID) async throws -> WeeklyReward?

    /// Update an existing weekly reward
    func update(_ reward: WeeklyReward) async throws -> WeeklyReward

    /// Delete a weekly reward
    func delete(_ rewardId: UUID) async throws

    /// Fetch unredeemed rewards for a child
    func fetchUnredeemed(for childId: UUID) async throws -> [WeeklyReward]

    /// Fetch rewards with tiers (earned at least bronze)
    func fetchWithTiers(for childId: UUID) async throws -> [WeeklyReward]
}
