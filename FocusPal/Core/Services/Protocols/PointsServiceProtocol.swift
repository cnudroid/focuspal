//
//  PointsServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the points service interface.
/// Manages point awarding, deduction, and tracking for children.
protocol PointsServiceProtocol {
    /// Award points to a child for a specific reason
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - amount: The number of points to award (must be positive)
    ///   - reason: The reason for awarding points
    ///   - activityId: Optional activity associated with the points
    /// - Throws: An error if the operation fails
    func awardPoints(childId: UUID, amount: Int, reason: PointsReason, activityId: UUID?) async throws

    /// Deduct points from a child for a specific reason
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - amount: The number of points to deduct (must be positive)
    ///   - reason: The reason for deducting points
    /// - Throws: An error if the operation fails
    func deductPoints(childId: UUID, amount: Int, reason: PointsReason) async throws

    /// Get today's points summary for a child
    /// - Parameter childId: The unique identifier of the child
    /// - Returns: The child's points for today
    /// - Throws: An error if the operation fails
    func getTodayPoints(for childId: UUID) async throws -> ChildPoints

    /// Get the total points earned this week for a child
    /// - Parameter childId: The unique identifier of the child
    /// - Returns: The total weekly points
    /// - Throws: An error if the operation fails
    func getWeeklyPoints(for childId: UUID) async throws -> Int

    /// Get the all-time total points for a child
    /// - Parameter childId: The unique identifier of the child
    /// - Returns: The total accumulated points
    /// - Throws: An error if the operation fails
    func getTotalPoints(for childId: UUID) async throws -> Int

    /// Get the transaction history for a child
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - limit: Maximum number of transactions to return
    /// - Returns: Array of point transactions, ordered by most recent first
    /// - Throws: An error if the operation fails
    func getTransactionHistory(for childId: UUID, limit: Int) async throws -> [PointsTransaction]
}
