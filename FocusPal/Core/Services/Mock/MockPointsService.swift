//
//  MockPointsService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of PointsService for testing and previews.
class MockPointsService: PointsServiceProtocol {

    // MARK: - Mock Data

    var mockChildPoints: [UUID: ChildPoints] = [:]
    var mockTransactions: [PointsTransaction] = []
    var mockError: Error?

    // MARK: - Call Tracking

    var awardPointsCallCount = 0
    var deductPointsCallCount = 0
    var getTodayPointsCallCount = 0
    var getWeeklyPointsCallCount = 0
    var getTotalPointsCallCount = 0
    var getTransactionHistoryCallCount = 0

    // MARK: - PointsServiceProtocol

    func awardPoints(childId: UUID, amount: Int, reason: PointsReason, activityId: UUID?) async throws {
        awardPointsCallCount += 1

        if let error = mockError {
            throw error
        }

        // Create transaction
        let transaction = PointsTransaction(
            childId: childId,
            activityId: activityId,
            amount: amount,
            reason: reason,
            timestamp: Date()
        )
        mockTransactions.append(transaction)

        // Update child points
        let todayPoints = try await getTodayPoints(for: childId)

        let updatedPoints: ChildPoints
        if isBonusReason(reason) {
            updatedPoints = ChildPoints(
                id: todayPoints.id,
                childId: todayPoints.childId,
                date: todayPoints.date,
                pointsEarned: todayPoints.pointsEarned,
                pointsDeducted: todayPoints.pointsDeducted,
                bonusPoints: todayPoints.bonusPoints + amount
            )
        } else {
            updatedPoints = ChildPoints(
                id: todayPoints.id,
                childId: todayPoints.childId,
                date: todayPoints.date,
                pointsEarned: todayPoints.pointsEarned + amount,
                pointsDeducted: todayPoints.pointsDeducted,
                bonusPoints: todayPoints.bonusPoints
            )
        }

        mockChildPoints[childId] = updatedPoints
    }

    func deductPoints(childId: UUID, amount: Int, reason: PointsReason) async throws {
        deductPointsCallCount += 1

        if let error = mockError {
            throw error
        }

        // Create transaction with negative amount
        let transaction = PointsTransaction(
            childId: childId,
            activityId: nil,
            amount: -amount,
            reason: reason,
            timestamp: Date()
        )
        mockTransactions.append(transaction)

        // Update child points
        let todayPoints = try await getTodayPoints(for: childId)

        let updatedPoints = ChildPoints(
            id: todayPoints.id,
            childId: todayPoints.childId,
            date: todayPoints.date,
            pointsEarned: todayPoints.pointsEarned,
            pointsDeducted: todayPoints.pointsDeducted + amount,
            bonusPoints: todayPoints.bonusPoints
        )

        mockChildPoints[childId] = updatedPoints
    }

    func getTodayPoints(for childId: UUID) async throws -> ChildPoints {
        getTodayPointsCallCount += 1

        if let error = mockError {
            throw error
        }

        // Return existing or create new
        if let existing = mockChildPoints[childId] {
            return existing
        }

        let todayPoints = ChildPoints(
            childId: childId,
            date: Date(),
            pointsEarned: 0,
            pointsDeducted: 0,
            bonusPoints: 0
        )
        mockChildPoints[childId] = todayPoints
        return todayPoints
    }

    func getWeeklyPoints(for childId: UUID) async throws -> Int {
        getWeeklyPointsCallCount += 1

        if let error = mockError {
            throw error
        }

        // Simplified: just return today's points for mock
        let todayPoints = try await getTodayPoints(for: childId)
        return todayPoints.totalPoints
    }

    func getTotalPoints(for childId: UUID) async throws -> Int {
        getTotalPointsCallCount += 1

        if let error = mockError {
            throw error
        }

        // Simplified: just return today's points for mock
        let todayPoints = try await getTodayPoints(for: childId)
        return todayPoints.totalPoints
    }

    func getTransactionHistory(for childId: UUID, limit: Int) async throws -> [PointsTransaction] {
        getTransactionHistoryCallCount += 1

        if let error = mockError {
            throw error
        }

        let childTransactions = mockTransactions
            .filter { $0.childId == childId }
            .sorted { $0.timestamp > $1.timestamp }

        return Array(childTransactions.prefix(limit))
    }

    // MARK: - Helper Methods

    /// Reset all mock data and counters
    func reset() {
        mockChildPoints = [:]
        mockTransactions = []
        mockError = nil
        awardPointsCallCount = 0
        deductPointsCallCount = 0
        getTodayPointsCallCount = 0
        getWeeklyPointsCallCount = 0
        getTotalPointsCallCount = 0
        getTransactionHistoryCallCount = 0
    }

    /// Set mock points for a child
    func setMockPoints(for childId: UUID, points: ChildPoints) {
        mockChildPoints[childId] = points
    }

    /// Add mock transactions
    func addMockTransactions(_ transactions: [PointsTransaction]) {
        mockTransactions.append(contentsOf: transactions)
    }

    /// Set an error to be thrown
    func setMockError(_ error: Error) {
        mockError = error
    }

    // MARK: - Private Helpers

    private func isBonusReason(_ reason: PointsReason) -> Bool {
        switch reason {
        case .earlyFinishBonus, .beatAverageBonus, .achievementUnlock, .weeklyReward:
            return true
        case .activityComplete, .activityIncomplete, .threeStrikePenalty, .rewardCost:
            return false
        }
    }
}
