//
//  PointsRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the points repository interface.
/// Abstracts data access for ChildPoints and PointsTransaction entities.
protocol PointsRepositoryProtocol {
    /// Create or update a ChildPoints record for a specific day
    /// - Parameter childPoints: The child points to save
    /// - Returns: The saved child points
    /// - Throws: An error if the operation fails
    func saveChildPoints(_ childPoints: ChildPoints) async throws -> ChildPoints

    /// Fetch ChildPoints for a child on a specific date
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - date: The date to fetch points for
    /// - Returns: The child points if found, nil otherwise
    /// - Throws: An error if the operation fails
    func fetchChildPoints(for childId: UUID, date: Date) async throws -> ChildPoints?

    /// Fetch ChildPoints for a child within a date range
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - dateRange: The date range to fetch points for
    /// - Returns: Array of child points within the date range
    /// - Throws: An error if the operation fails
    func fetchChildPoints(for childId: UUID, dateRange: DateInterval) async throws -> [ChildPoints]

    /// Create a new points transaction
    /// - Parameter transaction: The transaction to create
    /// - Returns: The created transaction
    /// - Throws: An error if the operation fails
    func createTransaction(_ transaction: PointsTransaction) async throws -> PointsTransaction

    /// Fetch transaction history for a child
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - limit: Maximum number of transactions to return
    /// - Returns: Array of transactions, ordered by most recent first
    /// - Throws: An error if the operation fails
    func fetchTransactions(for childId: UUID, limit: Int) async throws -> [PointsTransaction]

    /// Fetch transactions for a child within a date range
    /// - Parameters:
    ///   - childId: The unique identifier of the child
    ///   - dateRange: The date range to fetch transactions for
    /// - Returns: Array of transactions within the date range
    /// - Throws: An error if the operation fails
    func fetchTransactions(for childId: UUID, dateRange: DateInterval) async throws -> [PointsTransaction]
}
