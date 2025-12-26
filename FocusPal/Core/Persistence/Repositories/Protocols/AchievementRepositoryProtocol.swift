//
//  AchievementRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the achievement repository interface.
/// Abstracts data access for Achievement entities.
protocol AchievementRepositoryProtocol {
    /// Create a new achievement
    func create(_ achievement: Achievement) async throws -> Achievement

    /// Fetch all achievements for a child
    func fetchAll(for childId: UUID) async throws -> [Achievement]

    /// Fetch a specific achievement by child and type
    func fetch(for childId: UUID, achievementTypeId: String) async throws -> Achievement?

    /// Update an existing achievement
    func update(_ achievement: Achievement) async throws -> Achievement

    /// Delete an achievement
    func delete(_ achievementId: UUID) async throws

    /// Fetch all unlocked achievements for a child
    func fetchUnlocked(for childId: UUID) async throws -> [Achievement]

    /// Fetch all locked achievements for a child
    func fetchLocked(for childId: UUID) async throws -> [Achievement]
}
