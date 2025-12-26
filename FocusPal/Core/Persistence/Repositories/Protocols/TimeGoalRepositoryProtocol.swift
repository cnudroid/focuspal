//
//  TimeGoalRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the time goal repository interface.
/// Abstracts data access for TimeGoal entities.
protocol TimeGoalRepositoryProtocol {
    /// Create a new time goal
    func create(_ timeGoal: TimeGoal) async throws -> TimeGoal

    /// Fetch all time goals for a child
    func fetchAll(for childId: UUID) async throws -> [TimeGoal]

    /// Fetch time goal for a specific child and category
    func fetch(for childId: UUID, categoryId: UUID) async throws -> TimeGoal?

    /// Fetch a time goal by ID
    func fetch(by id: UUID) async throws -> TimeGoal?

    /// Update an existing time goal
    func update(_ timeGoal: TimeGoal) async throws -> TimeGoal

    /// Delete a time goal
    func delete(_ timeGoalId: UUID) async throws

    /// Fetch all active time goals for a child
    func fetchActive(for childId: UUID) async throws -> [TimeGoal]
}
