//
//  StatisticsViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Time period for statistics filtering
enum TimePeriod {
    case today
    case week
    case month

    var dateRange: DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return DateInterval(start: startOfDay, end: endOfDay)

        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -6, to: now)!
            let startOfDay = calendar.startOfDay(for: startOfWeek)
            return DateInterval(start: startOfDay, end: now)

        case .month:
            let startOfMonth = calendar.date(byAdding: .day, value: -29, to: now)!
            let startOfDay = calendar.startOfDay(for: startOfMonth)
            return DateInterval(start: startOfDay, end: now)
        }
    }

    var numberOfDays: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}

/// ViewModel for the Statistics screen.
/// Manages data loading and calculations for charts and insights.
@MainActor
class StatisticsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var dailyData: DailyStatistics = .empty
    @Published var weeklyData: WeeklyStatistics = .empty
    @Published var achievements: [AchievementDisplayItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimePeriod: TimePeriod = .today

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let child: Child

    // MARK: - Private Properties

    private var categories: [Category] = []

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol? = nil,
        categoryService: CategoryServiceProtocol? = nil,
        child: Child? = nil
    ) {
        self.activityService = activityService ?? MockActivityService()
        // Create a simple mock inline
        self.categoryService = categoryService ?? SimpleMockCategoryService()
        // For preview/testing purposes, create a default child if none provided
        self.child = child ?? Child(name: "Test Child", age: 8)
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load categories first
            categories = try await categoryService.fetchCategories(for: child)

            // Load activities for the selected time period
            let dateRange = selectedTimePeriod.dateRange
            let activities = try await activityService.fetchActivities(for: child, dateRange: dateRange)

            // Calculate statistics based on time period
            switch selectedTimePeriod {
            case .today:
                await loadDailyData(activities: activities)
            case .week, .month:
                await loadWeeklyData(activities: activities)
            }

            // Load achievements
            loadAchievements()

        } catch {
            errorMessage = "Failed to load statistics: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func loadDailyData(activities: [Activity]) async {
        let totalMinutes = calculateTotalMinutes(from: activities)
        let categoryBreakdown = calculateCategoryBreakdown(from: activities)
        let balanceScore = calculateBalanceScore(from: activities)

        dailyData = DailyStatistics(
            totalMinutes: totalMinutes,
            categoryBreakdown: categoryBreakdown,
            balanceScore: balanceScore
        )
    }

    private func loadWeeklyData(activities: [Activity]) async {
        let totalMinutes = calculateTotalMinutes(from: activities)
        let numberOfDays = selectedTimePeriod.numberOfDays
        let averageMinutesPerDay = numberOfDays > 0 ? totalMinutes / numberOfDays : 0

        let dailyBreakdown = calculateDailyBreakdown(from: activities)
        let streaks = calculateStreaks(from: activities)
        let insights = generateInsights(from: activities)

        weeklyData = WeeklyStatistics(
            totalMinutes: totalMinutes,
            averageMinutesPerDay: averageMinutesPerDay,
            dailyBreakdown: dailyBreakdown,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            insights: insights
        )
    }

    private func loadAchievements() {
        achievements = AchievementType.allCases.map { type in
            let isUnlocked = [.firstTimer].contains(type)
            let progress: Double

            switch type {
            case .firstTimer: progress = 100
            case .streak3Day: progress = 66
            case .streak7Day: progress = 28
            case .homeworkHero: progress = 45
            default: progress = Double.random(in: 0...50)
            }

            return AchievementDisplayItem(
                id: UUID(),
                name: type.name,
                description: type.description,
                iconName: type.iconName,
                isUnlocked: isUnlocked,
                progress: progress,
                unlockedDate: isUnlocked ? Date() : nil
            )
        }
    }

    // MARK: - Calculation Methods

    private func calculateTotalMinutes(from activities: [Activity]) -> Int {
        activities.reduce(0) { $0 + $1.durationMinutes }
    }

    private func calculateCategoryBreakdown(from activities: [Activity]) -> [CategoryBreakdownItem] {
        // Group activities by category
        var categoryMinutes: [UUID: Int] = [:]

        for activity in activities {
            categoryMinutes[activity.categoryId, default: 0] += activity.durationMinutes
        }

        let totalMinutes = calculateTotalMinutes(from: activities)

        // Create breakdown items
        return categoryMinutes.compactMap { categoryId, minutes in
            guard let category = categories.first(where: { $0.id == categoryId }) else {
                return nil
            }

            let percentage = totalMinutes > 0 ? (minutes * 100) / totalMinutes : 0

            return CategoryBreakdownItem(
                categoryName: category.name,
                colorHex: category.colorHex,
                minutes: minutes,
                percentage: percentage
            )
        }.sorted { $0.minutes > $1.minutes }
    }

    private func calculateBalanceScore(from activities: [Activity]) -> Int {
        // Define productive vs non-productive categories
        let productiveCategories = ["Homework", "Reading", "Sports", "Music"]
        let nonProductiveCategories = ["Screen Time", "Playing"]

        var productiveMinutes = 0
        var nonProductiveMinutes = 0

        for activity in activities {
            guard let category = categories.first(where: { $0.id == activity.categoryId }) else {
                continue
            }

            if productiveCategories.contains(category.name) {
                productiveMinutes += activity.durationMinutes
            } else if nonProductiveCategories.contains(category.name) {
                nonProductiveMinutes += activity.durationMinutes
            }
        }

        // Calculate balance score (0-100)
        let totalMinutes = productiveMinutes + nonProductiveMinutes

        if totalMinutes == 0 {
            return 0
        }

        // Perfect balance is when productive >= non-productive
        if nonProductiveMinutes == 0 {
            // Only productive activities = perfect score
            return 100
        }

        // Calculate ratio: productive / total
        let productiveRatio = Double(productiveMinutes) / Double(totalMinutes)

        // Score based on productive ratio
        // 100% productive = 100 score
        // 50% productive = 80 score (good balance)
        // 25% productive = 40 score (fair)
        // 0% productive = 0 score

        if productiveRatio >= 0.5 {
            // Above 50% productive: scale from 80-100
            return Int(80 + (productiveRatio - 0.5) * 40)
        } else {
            // Below 50% productive: scale from 0-80
            return Int(productiveRatio * 160)
        }
    }

    private func calculateDailyBreakdown(from activities: [Activity]) -> [DailyBarData] {
        let calendar = Calendar.current
        let dateRange = selectedTimePeriod.dateRange

        // Group activities by day
        var dailyMinutes: [Date: Int] = [:]

        for activity in activities {
            let dayStart = calendar.startOfDay(for: activity.startTime)
            dailyMinutes[dayStart, default: 0] += activity.durationMinutes
        }

        // Create bar data for each day in the range
        var breakdown: [DailyBarData] = []
        let numberOfDays = selectedTimePeriod.numberOfDays

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        for i in 0..<numberOfDays {
            let date = calendar.date(byAdding: .day, value: -(numberOfDays - 1 - i), to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let minutes = dailyMinutes[dayStart] ?? 0
            let dayLabel = dayFormatter.string(from: date)

            breakdown.append(DailyBarData(
                dayLabel: dayLabel,
                minutes: minutes,
                date: dayStart
            ))
        }

        return breakdown.sorted { $0.date < $1.date }
    }

    private func calculateStreaks(from activities: [Activity]) -> (current: Int, longest: Int) {
        if activities.isEmpty {
            return (0, 0)
        }

        let calendar = Calendar.current

        // Get unique days with activities
        let activeDays = Set(activities.map { calendar.startOfDay(for: $0.startTime) })
            .sorted()

        if activeDays.isEmpty {
            return (0, 0)
        }

        // Calculate current streak (counting backwards from today)
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())

        for i in 0..<365 { // Check up to a year back
            let checkDate = calendar.date(byAdding: .day, value: -i, to: today)!
            if activeDays.contains(checkDate) {
                currentStreak += 1
            } else {
                break
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 1

        for i in 1..<activeDays.count {
            let daysDiff = calendar.dateComponents([.day], from: activeDays[i-1], to: activeDays[i]).day ?? 0

            if daysDiff == 1 {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }

        longestStreak = max(longestStreak, tempStreak)

        return (currentStreak, longestStreak)
    }

    private func generateInsights(from activities: [Activity]) -> [String] {
        var insights: [String] = []

        // Consistency insight
        let streaks = calculateStreaks(from: activities)
        if streaks.current >= 3 {
            insights.append("Great job staying consistent!")
        }

        // Category-specific insights
        let categoryBreakdown = calculateCategoryBreakdown(from: activities)

        if let topCategory = categoryBreakdown.first {
            insights.append("\(topCategory.categoryName) is your most logged activity")
        }

        // Balance insight
        let balanceScore = calculateBalanceScore(from: activities)
        if balanceScore >= 80 {
            insights.append("Excellent balance between activities!")
        } else if balanceScore < 50 {
            insights.append("Try adding more productive activities")
        }

        return insights
    }
}

// MARK: - Simple Mock for Development

private class SimpleMockCategoryService: CategoryServiceProtocol {
    func fetchCategories(for child: Child) async throws -> [Category] { [] }
    func fetchActiveCategories(for child: Child) async throws -> [Category] { [] }
    func createCategory(_ category: Category) async throws -> Category { category }
    func updateCategory(_ category: Category) async throws -> Category { category }
    func deleteCategory(_ categoryId: UUID) async throws { }
    func reorderCategories(_ categoryIds: [UUID]) async throws { }
    func createDefaultCategories(for child: Child) async throws -> [Category] { [] }
}
