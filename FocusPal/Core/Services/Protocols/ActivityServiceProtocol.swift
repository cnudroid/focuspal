//
//  ActivityServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the activity service interface.
/// Manages activity logging and retrieval operations.
protocol ActivityServiceProtocol {
    /// Log a new activity
    func logActivity(category: Category, duration: TimeInterval, child: Child) async throws -> Activity

    /// Fetch today's activities for a child
    func fetchTodayActivities(for child: Child) async throws -> [Activity]

    /// Fetch activities within a date range
    func fetchActivities(for child: Child, dateRange: DateInterval) async throws -> [Activity]

    /// Update an existing activity
    func updateActivity(_ activity: Activity) async throws -> Activity

    /// Delete an activity
    func deleteActivity(_ activityId: UUID) async throws

    /// Calculate daily aggregates by category
    func calculateDailyAggregates(for child: Child, date: Date) async throws -> [CategoryAggregate]
}

/// Aggregate data for a category over a time period
struct CategoryAggregate: Identifiable, Equatable {
    let id: UUID
    let category: Category
    let totalMinutes: Int
    let activityCount: Int
    let averageDuration: TimeInterval

    init(
        id: UUID = UUID(),
        category: Category,
        totalMinutes: Int,
        activityCount: Int
    ) {
        self.id = id
        self.category = category
        self.totalMinutes = totalMinutes
        self.activityCount = activityCount
        self.averageDuration = activityCount > 0 ? Double(totalMinutes * 60) / Double(activityCount) : 0
    }
}
