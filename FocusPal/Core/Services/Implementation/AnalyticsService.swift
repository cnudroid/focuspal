//
//  AnalyticsService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Service for calculating and providing analytics data.
/// Processes activity data to generate insights and statistics.
class AnalyticsService {

    // MARK: - Properties

    private let activityService: ActivityServiceProtocol

    // MARK: - Initialization

    init(activityService: ActivityServiceProtocol) {
        self.activityService = activityService
    }

    // MARK: - Analytics Methods

    /// Calculate weekly summary for a child
    func calculateWeeklySummary(for child: Child, weekOf date: Date) async throws -> WeeklySummary {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let dateRange = DateInterval(start: weekStart, end: weekEnd)
        let activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)

        let totalMinutes = activities.reduce(0) { $0 + $1.durationMinutes }
        let activityDays = Set(activities.map { Calendar.current.startOfDay(for: $0.startTime) }).count

        return WeeklySummary(
            weekStart: weekStart,
            totalMinutes: totalMinutes,
            activityCount: activities.count,
            activeDays: activityDays,
            averageMinutesPerDay: activityDays > 0 ? totalMinutes / activityDays : 0
        )
    }

    /// Calculate balance score based on activity distribution
    func calculateBalanceScore(for child: Child, date: Date) async throws -> BalanceScore {
        let aggregates = try await activityService.calculateDailyAggregates(for: child, date: date)

        // Calculate balance based on variety and distribution
        let categoryCount = aggregates.count
        let totalMinutes = aggregates.reduce(0) { $0 + $1.totalMinutes }

        guard categoryCount > 0, totalMinutes > 0 else {
            return BalanceScore(score: 0, level: .needsImprovement, breakdown: [:])
        }

        // Calculate standard deviation for balance
        let averageMinutes = Double(totalMinutes) / Double(categoryCount)
        let variance = aggregates.reduce(0.0) { sum, agg in
            let diff = Double(agg.totalMinutes) - averageMinutes
            return sum + (diff * diff)
        } / Double(categoryCount)

        let stdDev = sqrt(variance)
        let coefficientOfVariation = stdDev / averageMinutes

        // Lower CV = more balanced (score 0-100)
        let score = max(0, min(100, Int(100 * (1 - coefficientOfVariation))))

        let level: BalanceLevel
        switch score {
        case 80...100: level = .excellent
        case 60..<80: level = .good
        case 40..<60: level = .fair
        default: level = .needsImprovement
        }

        var breakdown: [String: Int] = [:]
        for aggregate in aggregates {
            breakdown[aggregate.category.name] = aggregate.totalMinutes
        }

        return BalanceScore(score: score, level: level, breakdown: breakdown)
    }
}

/// Weekly summary data structure
struct WeeklySummary {
    let weekStart: Date
    let totalMinutes: Int
    let activityCount: Int
    let activeDays: Int
    let averageMinutesPerDay: Int
}

/// Balance score data structure
struct BalanceScore {
    let score: Int  // 0-100
    let level: BalanceLevel
    let breakdown: [String: Int]
}

/// Balance level categories
enum BalanceLevel: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsImprovement = "Needs Improvement"

    var color: String {
        switch self {
        case .excellent: return "#4CAF50"
        case .good: return "#8BC34A"
        case .fair: return "#FFC107"
        case .needsImprovement: return "#FF5722"
        }
    }
}
