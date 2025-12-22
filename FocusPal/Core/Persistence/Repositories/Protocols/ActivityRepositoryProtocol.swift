//
//  ActivityRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the activity repository interface.
/// Abstracts data access for Activity entities.
protocol ActivityRepositoryProtocol {
    /// Create a new activity
    func create(_ activity: Activity) async throws -> Activity

    /// Fetch activities for a child within a date range
    func fetch(for childId: UUID, dateRange: DateInterval) async throws -> [Activity]

    /// Fetch a specific activity by ID
    func fetch(by id: UUID) async throws -> Activity?

    /// Update an existing activity
    func update(_ activity: Activity) async throws -> Activity

    /// Delete an activity
    func delete(_ activityId: UUID) async throws

    /// Fetch activities by category
    func fetch(for childId: UUID, categoryId: UUID) async throws -> [Activity]

    /// Fetch activities pending sync
    func fetchPendingSync() async throws -> [Activity]

    /// Mark activities as synced
    func markSynced(_ activityIds: [UUID]) async throws
}
