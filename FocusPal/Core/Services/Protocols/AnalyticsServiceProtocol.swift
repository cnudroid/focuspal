//
//  AnalyticsServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the analytics service interface.
/// Provides analytics calculations and insights.
protocol AnalyticsServiceProtocol {
    /// Calculate weekly summary for a child
    func calculateWeeklySummary(for child: Child?, weekOf date: Date) async throws -> AnalyticsWeeklySummary

    /// Calculate balance score based on activity distribution
    func calculateBalanceScore(for child: Child?, in dateRange: DateInterval) async throws -> BalanceScore

    /// Calculate category breakdown with percentages
    func calculateCategoryBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [CategoryBreakdownItem]

    /// Calculate daily breakdown
    func calculateDailyBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [DailyBreakdownItem]
}

/// Category breakdown item with percentage
struct CategoryBreakdownItem: Identifiable, Equatable {
    let id: UUID
    let category: Category?
    let categoryName: String
    let colorHex: String
    let minutes: Int
    let percentage: Int

    // Computed property for compatibility
    var totalMinutes: Int { minutes }

    init(id: UUID = UUID(), category: Category, totalMinutes: Int, percentage: Double) {
        self.id = id
        self.category = category
        self.categoryName = category.name
        self.colorHex = category.colorHex
        self.minutes = totalMinutes
        self.percentage = Int(percentage)
    }

    init(categoryName: String, colorHex: String, minutes: Int, percentage: Int) {
        self.id = UUID()
        self.category = nil
        self.categoryName = categoryName
        self.colorHex = colorHex
        self.minutes = minutes
        self.percentage = percentage
    }
}

/// Daily breakdown item
struct DailyBreakdownItem: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let totalMinutes: Int
    let activityCount: Int
}
