//
//  TimeGoalServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the time goal service interface.
/// Manages time goal tracking, warnings, and enforcement.
protocol TimeGoalServiceProtocol {
    /// Get total time used today for a specific category
    /// - Parameters:
    ///   - categoryId: The category to track
    ///   - childId: The child profile
    /// - Returns: Total minutes used today
    func getTimeUsedToday(categoryId: UUID, childId: UUID) async throws -> Int

    /// Check the current status of a time goal
    /// - Parameter goal: The time goal to check
    /// - Returns: Current goal status (normal, warning, or exceeded)
    func checkGoalStatus(goal: TimeGoal) async throws -> TimeGoalStatus

    /// Track time usage and send notifications if thresholds are reached
    /// - Parameters:
    ///   - categoryId: The category to track
    ///   - childId: The child profile
    ///   - category: The category model for notification messages
    ///   - goal: The time goal to enforce
    func trackTimeAndNotify(
        categoryId: UUID,
        childId: UUID,
        category: Category,
        goal: TimeGoal
    ) async throws

    /// Calculate progress percentage for a time goal
    /// - Parameter goal: The time goal to calculate progress for
    /// - Returns: Progress percentage (0-100)
    func calculateProgress(goal: TimeGoal) async throws -> Double

    /// Reset daily tracking (called at midnight)
    func resetDailyTracking()

    /// Check if midnight reset is scheduled
    /// - Returns: True if midnight reset is scheduled
    func hasMidnightResetScheduled() -> Bool
}

/// Status of a time goal
enum TimeGoalStatus: Equatable {
    case normal        // Below warning threshold
    case warning       // At or above warning threshold, below goal
    case exceeded      // At or above recommended time
}
