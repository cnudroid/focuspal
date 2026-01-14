//
//  WidgetDataService.swift
//  FocusPal
//
//  Provides data to home screen widgets by writing to shared App Group container.
//

import Foundation
import WidgetKit

/// Manages widget data updates from the main app
@MainActor
class WidgetDataService {

    // MARK: - Singleton

    static let shared = WidgetDataService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Update widget data for a specific child
    func updateWidgetData(
        for child: Child,
        activityService: ActivityServiceProtocol,
        pointsService: PointsServiceProtocol,
        timerManager: MultiChildTimerManager
    ) async {
        do {
            // Get today's date range
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            let todayRange = DateInterval(start: startOfToday, end: endOfToday)

            // Fetch today's activities
            let todayActivities = try await activityService.fetchActivities(
                for: child,
                dateRange: todayRange
            )

            // Calculate today's total minutes
            let todayTotalMinutes = todayActivities.reduce(0) { $0 + $1.durationMinutes }

            // Get category progress
            let categoryProgress = buildCategoryProgress(from: todayActivities, for: child)

            // Get top categories for quick actions
            let topCategories = getTopCategories(for: child)

            // Get weekly data
            let weeklyMinutes = await getWeeklyMinutes(for: child, activityService: activityService)

            // Get recent activities
            let recentActivities = todayActivities.prefix(5).map { activity in
                RecentActivity(
                    id: activity.id,
                    categoryName: getCategoryName(for: activity.categoryId, childId: child.id),
                    iconName: getCategoryIcon(for: activity.categoryId, childId: child.id),
                    colorHex: getCategoryColor(for: activity.categoryId, childId: child.id),
                    durationMinutes: activity.durationMinutes,
                    completedAt: activity.endTime
                )
            }

            // Get points
            let totalPoints = (try? await pointsService.getPoints(for: child.id)) ?? 0

            // Get streak (simplified - count consecutive days with activity)
            let streak = await calculateStreak(for: child, activityService: activityService)

            // Get active timer info
            let activeTimer = getActiveTimerInfo(for: child.id, timerManager: timerManager)

            // Build widget data
            let widgetData = WidgetData(
                childName: child.name,
                childId: child.id,
                currentStreak: streak,
                todayTotalMinutes: todayTotalMinutes,
                todayCategories: categoryProgress,
                topCategories: topCategories,
                weeklyMinutes: weeklyMinutes,
                recentActivities: Array(recentActivities),
                totalPoints: totalPoints,
                activeTimer: activeTimer,
                lastUpdated: Date()
            )

            // Save to shared container
            widgetData.save()

            // Reload widgets
            WidgetCenter.shared.reloadAllTimelines()

            print("📊 Widget data updated for \(child.name)")
        } catch {
            print("❌ Failed to update widget data: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func buildCategoryProgress(from activities: [Activity], for child: Child) -> [CategoryProgress] {
        // Group activities by category
        var categoryMinutes: [UUID: Int] = [:]
        for activity in activities {
            categoryMinutes[activity.categoryId, default: 0] += activity.durationMinutes
        }

        // Get categories
        let categories = loadCategories(for: child.id)

        return categories.compactMap { category in
            let minutes = categoryMinutes[category.id] ?? 0
            guard minutes > 0 else { return nil }

            return CategoryProgress(
                id: category.id,
                name: category.name,
                iconName: category.iconName,
                colorHex: category.colorHex,
                minutes: minutes,
                goalMinutes: nil
            )
        }
    }

    private func getTopCategories(for child: Child) -> [QuickCategory] {
        let categories = loadCategories(for: child.id)
        return categories.prefix(3).map { category in
            QuickCategory(
                id: category.id,
                name: category.name,
                iconName: category.iconName,
                colorHex: category.colorHex,
                durationMinutes: category.durationMinutes
            )
        }
    }

    private func getWeeklyMinutes(for child: Child, activityService: ActivityServiceProtocol) async -> [Int] {
        var weeklyMinutes: [Int] = []
        let calendar = Calendar.current

        for daysAgo in (0...6).reversed() {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            do {
                let activities = try await activityService.fetchActivities(
                    for: child,
                    dateRange: DateInterval(start: startOfDay, end: endOfDay)
                )
                let minutes = activities.reduce(0) { $0 + $1.durationMinutes }
                weeklyMinutes.append(minutes)
            } catch {
                weeklyMinutes.append(0)
            }
        }

        return weeklyMinutes
    }

    private func calculateStreak(for child: Child, activityService: ActivityServiceProtocol) async -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        // Check backwards from today
        for _ in 0..<365 {
            let startOfDay = calendar.startOfDay(for: checkDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            do {
                let activities = try await activityService.fetchActivities(
                    for: child,
                    dateRange: DateInterval(start: startOfDay, end: endOfDay)
                )

                if activities.isEmpty {
                    break
                }

                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } catch {
                break
            }
        }

        return streak
    }

    private func getActiveTimerInfo(for childId: UUID, timerManager: MultiChildTimerManager) -> ActiveTimerInfo? {
        guard let timerState = timerManager.timerState(for: childId),
              !timerState.isCompleted else {
            return nil
        }

        return ActiveTimerInfo(
            childName: timerState.childName,
            categoryName: timerState.categoryName,
            iconName: timerState.categoryIconName,
            colorHex: timerState.categoryColorHex,
            remainingSeconds: Int(timerState.remainingTime),
            totalSeconds: Int(timerState.totalDuration),
            isPaused: timerState.isPaused
        )
    }

    private func loadCategories(for childId: UUID) -> [Category] {
        let key = "globalCategories"
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) else {
            return Category.defaultCategories(for: childId)
        }
        return decoded.map { $0.toCategory(childId: childId) }.filter { $0.isActive }
    }

    private func getCategoryName(for categoryId: UUID, childId: UUID) -> String {
        loadCategories(for: childId).first { $0.id == categoryId }?.name ?? "Activity"
    }

    private func getCategoryIcon(for categoryId: UUID, childId: UUID) -> String {
        loadCategories(for: childId).first { $0.id == categoryId }?.iconName ?? "circle.fill"
    }

    private func getCategoryColor(for categoryId: UUID, childId: UUID) -> String {
        loadCategories(for: childId).first { $0.id == categoryId }?.colorHex ?? "#888888"
    }
}
