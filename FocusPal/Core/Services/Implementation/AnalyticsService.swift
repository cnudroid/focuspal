//
//  AnalyticsService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Service for calculating and providing analytics data.
/// Processes activity data to generate insights and statistics.
class AnalyticsService: AnalyticsServiceProtocol {

    // MARK: - Properties

    let activityService: ActivityServiceProtocol
    let categoryService: CategoryServiceProtocol

    // MARK: - Initialization

    init(activityService: ActivityServiceProtocol, categoryService: CategoryServiceProtocol) {
        self.activityService = activityService
        self.categoryService = categoryService
    }

    // MARK: - Analytics Methods

    /// Calculate weekly summary for a child or all children
    func calculateWeeklySummary(for child: Child?, weekOf date: Date) async throws -> WeeklySummary {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let dateRange = DateInterval(start: weekStart, end: weekEnd)

        let activities: [Activity]
        if let child = child {
            activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)
        } else {
            // For now, if no child specified, return empty (would need all children logic)
            activities = []
        }

        let totalMinutes = activities.reduce(0) { $0 + $1.durationMinutes }
        let activityDays = Set(activities.map { calendar.startOfDay(for: $0.startTime) }).count

        return WeeklySummary(
            weekStart: weekStart,
            totalMinutes: totalMinutes,
            activityCount: activities.count,
            activeDays: activityDays,
            averageMinutesPerDay: activityDays > 0 ? totalMinutes / activityDays : 0
        )
    }

    /// Calculate balance score based on activity distribution
    func calculateBalanceScore(for child: Child?, in dateRange: DateInterval) async throws -> BalanceScore {
        let activities: [Activity]
        if let child = child {
            activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)
        } else {
            activities = []
        }

        // Group by category
        var categoryMinutes: [UUID: Int] = [:]
        for activity in activities {
            categoryMinutes[activity.categoryId, default: 0] += activity.durationMinutes
        }

        guard !categoryMinutes.isEmpty else {
            return BalanceScore(score: 0, level: .needsImprovement, breakdown: [:])
        }

        // Calculate balance based on variety and distribution
        let categoryCount = categoryMinutes.count
        let totalMinutes = categoryMinutes.values.reduce(0, +)

        // Calculate standard deviation for balance
        let averageMinutes = Double(totalMinutes) / Double(categoryCount)
        let variance = categoryMinutes.values.reduce(0.0) { sum, minutes in
            let diff = Double(minutes) - averageMinutes
            return sum + (diff * diff)
        } / Double(categoryCount)

        let stdDev = sqrt(variance)
        let coefficientOfVariation = averageMinutes > 0 ? stdDev / averageMinutes : 0

        // Lower CV = more balanced (score 0-100)
        let score = max(0, min(100, Int(100 * (1 - coefficientOfVariation))))

        let level: BalanceLevel
        switch score {
        case 80...100: level = .excellent
        case 60..<80: level = .good
        case 40..<60: level = .fair
        default: level = .needsImprovement
        }

        // Build breakdown with category names
        var breakdown: [String: Int] = [:]
        let categories = child != nil ? (try? await categoryService.fetchCategories(for: child!)) ?? [] : []
        for (categoryId, minutes) in categoryMinutes {
            if let category = categories.first(where: { $0.id == categoryId }) {
                breakdown[category.name] = minutes
            }
        }

        return BalanceScore(score: score, level: level, breakdown: breakdown)
    }

    /// Calculate category breakdown with percentages
    func calculateCategoryBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [CategoryBreakdownItem] {
        let activities: [Activity]
        if let child = child {
            activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)
        } else {
            activities = []
        }

        // Group by category
        var categoryMinutes: [UUID: Int] = [:]
        for activity in activities {
            categoryMinutes[activity.categoryId, default: 0] += activity.durationMinutes
        }

        let totalMinutes = categoryMinutes.values.reduce(0, +)
        guard totalMinutes > 0 else {
            return []
        }

        // Get categories
        let categories = child != nil ? (try? await categoryService.fetchCategories(for: child!)) ?? [] : []

        // Build breakdown items
        var items: [CategoryBreakdownItem] = []
        for (categoryId, minutes) in categoryMinutes {
            if let category = categories.first(where: { $0.id == categoryId }) {
                let percentage = (Double(minutes) / Double(totalMinutes)) * 100.0
                items.append(CategoryBreakdownItem(
                    category: category,
                    totalMinutes: minutes,
                    percentage: percentage
                ))
            }
        }

        return items
    }

    /// Calculate daily breakdown for date range
    func calculateDailyBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [DailyBreakdownItem] {
        let activities: [Activity]
        if let child = child {
            activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)
        } else {
            activities = []
        }

        let calendar = Calendar.current

        // Group activities by day
        var dailyData: [Date: (minutes: Int, count: Int)] = [:]
        for activity in activities {
            let day = calendar.startOfDay(for: activity.startTime)
            let existing = dailyData[day] ?? (minutes: 0, count: 0)
            dailyData[day] = (minutes: existing.minutes + activity.durationMinutes, count: existing.count + 1)
        }

        // Create items for all days in range
        var items: [DailyBreakdownItem] = []
        var currentDate = calendar.startOfDay(for: dateRange.start)
        let endDate = calendar.startOfDay(for: dateRange.end)

        while currentDate < endDate {
            let data = dailyData[currentDate] ?? (minutes: 0, count: 0)
            items.append(DailyBreakdownItem(
                date: currentDate,
                totalMinutes: data.minutes,
                activityCount: data.count
            ))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return items
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
