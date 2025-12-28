//
//  PointsService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Errors that can occur in the points service
enum PointsServiceError: Error, Equatable {
    case invalidAmount
    case childNotFound
}

/// Concrete implementation of the points service.
/// Manages point awarding, deduction, and tracking for children.
class PointsService: PointsServiceProtocol {

    // MARK: - Constants

    /// Standard point values for various actions
    enum Constants {
        static let activityComplete = 10
        static let activityIncomplete = 5
        static let earlyFinishBonus = 5
        static let beatAverageBonus = 3
        static let threeStrikePenalty = 15
        static let achievementUnlock = 20
    }

    // MARK: - Properties

    private let repository: PointsRepositoryProtocol

    // MARK: - Initialization

    init(repository: PointsRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - PointsServiceProtocol

    func awardPoints(childId: UUID, amount: Int, reason: PointsReason, activityId: UUID?) async throws {
        // Validate amount
        guard amount > 0 else {
            throw PointsServiceError.invalidAmount
        }

        // Create transaction
        let transaction = PointsTransaction(
            childId: childId,
            activityId: activityId,
            amount: amount,
            reason: reason,
            timestamp: Date()
        )
        _ = try await repository.createTransaction(transaction)

        // Update today's points
        let todayPoints = try await getTodayPoints(for: childId)

        let updatedPoints: ChildPoints
        if isBonusReason(reason) {
            // Add to bonus points
            updatedPoints = ChildPoints(
                id: todayPoints.id,
                childId: todayPoints.childId,
                date: todayPoints.date,
                pointsEarned: todayPoints.pointsEarned,
                pointsDeducted: todayPoints.pointsDeducted,
                bonusPoints: todayPoints.bonusPoints + amount
            )
        } else {
            // Add to earned points
            updatedPoints = ChildPoints(
                id: todayPoints.id,
                childId: todayPoints.childId,
                date: todayPoints.date,
                pointsEarned: todayPoints.pointsEarned + amount,
                pointsDeducted: todayPoints.pointsDeducted,
                bonusPoints: todayPoints.bonusPoints
            )
        }

        _ = try await repository.saveChildPoints(updatedPoints)
    }

    func deductPoints(childId: UUID, amount: Int, reason: PointsReason) async throws {
        // Validate amount
        guard amount > 0 else {
            throw PointsServiceError.invalidAmount
        }

        // Create transaction with negative amount
        let transaction = PointsTransaction(
            childId: childId,
            activityId: nil,
            amount: -amount,
            reason: reason,
            timestamp: Date()
        )
        _ = try await repository.createTransaction(transaction)

        // Update today's points
        let todayPoints = try await getTodayPoints(for: childId)

        let updatedPoints = ChildPoints(
            id: todayPoints.id,
            childId: todayPoints.childId,
            date: todayPoints.date,
            pointsEarned: todayPoints.pointsEarned,
            pointsDeducted: todayPoints.pointsDeducted + amount,
            bonusPoints: todayPoints.bonusPoints
        )

        _ = try await repository.saveChildPoints(updatedPoints)
    }

    func getTodayPoints(for childId: UUID) async throws -> ChildPoints {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Try to fetch existing record
        if let existingPoints = try await repository.fetchChildPoints(for: childId, date: today) {
            return existingPoints
        }

        // Create new record for today with deterministic ID
        let todayPoints = ChildPoints(
            id: ChildPoints.deterministicId(childId: childId, date: today),
            childId: childId,
            date: today,
            pointsEarned: 0,
            pointsDeducted: 0,
            bonusPoints: 0
        )

        return try await repository.saveChildPoints(todayPoints)
    }

    func getWeeklyPoints(for childId: UUID) async throws -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get start of current week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else {
            return 0
        }

        // Get end of current week
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let dateRange = DateInterval(start: weekStart, end: weekEnd)
        let weekPoints = try await repository.fetchChildPoints(for: childId, dateRange: dateRange)

        return weekPoints.reduce(0) { $0 + $1.totalPoints }
    }

    func getTotalPoints(for childId: UUID) async throws -> Int {
        // Fetch all points from beginning of time
        let distantPast = Date(timeIntervalSince1970: 0)
        let now = Date().addingTimeInterval(86400) // Add 1 day to include today
        let dateRange = DateInterval(start: distantPast, end: now)

        let allPoints = try await repository.fetchChildPoints(for: childId, dateRange: dateRange)

        return allPoints.reduce(0) { $0 + $1.totalPoints }
    }

    func getTransactionHistory(for childId: UUID, limit: Int) async throws -> [PointsTransaction] {
        return try await repository.fetchTransactions(for: childId, limit: limit)
    }

    // MARK: - Private Helpers

    /// Determines if a reason should count as bonus points
    private func isBonusReason(_ reason: PointsReason) -> Bool {
        switch reason {
        case .earlyFinishBonus, .beatAverageBonus, .achievementUnlock, .weeklyReward:
            return true
        case .activityComplete, .activityIncomplete, .threeStrikePenalty:
            return false
        }
    }
}
