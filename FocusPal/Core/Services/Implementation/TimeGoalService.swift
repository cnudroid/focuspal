//
//  TimeGoalService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Concrete implementation of the time goal service.
/// Manages time goal tracking, warnings, and enforcement with daily reset logic.
class TimeGoalService: TimeGoalServiceProtocol {

    // MARK: - Properties

    private let activityService: ActivityServiceProtocol
    private let notificationService: NotificationServiceProtocol

    /// Track which goals have already sent warning notifications today
    private var warningNotificationsSentToday: Set<String> = []

    /// Track which goals have already sent exceeded notifications today
    private var exceededNotificationsSentToday: Set<String> = []

    /// Timer for midnight reset
    private var midnightResetTimer: Timer?

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.activityService = activityService
        self.notificationService = notificationService
        scheduleMidnightReset()
    }

    deinit {
        midnightResetTimer?.invalidate()
    }

    // MARK: - TimeGoalServiceProtocol

    func getTimeUsedToday(categoryId: UUID, childId: UUID) async throws -> Int {
        // Create a temporary child object for fetching activities
        let child = Child(id: childId, name: "Temp", age: 0)

        // Fetch today's activities
        let activities = try await activityService.fetchTodayActivities(for: child)

        // Filter by category and sum durations
        let totalSeconds = activities
            .filter { $0.categoryId == categoryId }
            .reduce(0) { $0 + Int($1.duration) }

        // Convert to minutes
        return totalSeconds / 60
    }

    func checkGoalStatus(goal: TimeGoal) async throws -> TimeGoalStatus {
        // Inactive goals always return normal status
        guard goal.isActive else {
            return .normal
        }

        // Get current time used
        let timeUsed = try await getTimeUsedToday(
            categoryId: goal.categoryId,
            childId: goal.childId
        )

        // Check if goal is exceeded
        if goal.isExceeded(currentMinutes: timeUsed) {
            return .exceeded
        }

        // Check if warning threshold is reached
        if goal.shouldWarn(currentMinutes: timeUsed) {
            return .warning
        }

        return .normal
    }

    func trackTimeAndNotify(
        categoryId: UUID,
        childId: UUID,
        category: Category,
        goal: TimeGoal
    ) async throws {
        // Only track active goals
        guard goal.isActive else {
            return
        }

        // Get current status
        let status = try await checkGoalStatus(goal: goal)
        let timeUsed = try await getTimeUsedToday(categoryId: categoryId, childId: childId)

        // Create notification key for deduplication
        let notificationKey = "\(childId.uuidString)_\(categoryId.uuidString)"

        // Send notifications based on status
        switch status {
        case .exceeded:
            // Only notify once per day for exceeded
            if !exceededNotificationsSentToday.contains(notificationKey) {
                notificationService.scheduleTimeGoalExceeded(
                    category: category.name,
                    timeUsed: timeUsed,
                    goalTime: goal.recommendedMinutes
                )
                exceededNotificationsSentToday.insert(notificationKey)
            }

        case .warning:
            // Only notify once per day for warning
            if !warningNotificationsSentToday.contains(notificationKey) {
                notificationService.scheduleTimeGoalWarning(
                    category: category.name,
                    timeUsed: timeUsed,
                    goalTime: goal.recommendedMinutes
                )
                warningNotificationsSentToday.insert(notificationKey)
            }

        case .normal:
            // No notification needed
            break
        }
    }

    func calculateProgress(goal: TimeGoal) async throws -> Double {
        let timeUsed = try await getTimeUsedToday(
            categoryId: goal.categoryId,
            childId: goal.childId
        )

        return goal.progressPercentage(currentMinutes: timeUsed)
    }

    func resetDailyTracking() {
        warningNotificationsSentToday.removeAll()
        exceededNotificationsSentToday.removeAll()
    }

    func hasMidnightResetScheduled() -> Bool {
        return midnightResetTimer != nil && midnightResetTimer?.isValid == true
    }

    // MARK: - Private Methods

    private func scheduleMidnightReset() {
        // Calculate time until next midnight
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let timeUntilMidnight = tomorrow.timeIntervalSince(now)

        // Schedule timer to fire at midnight
        midnightResetTimer = Timer.scheduledTimer(
            withTimeInterval: timeUntilMidnight,
            repeats: false
        ) { [weak self] _ in
            self?.resetDailyTracking()
            // Reschedule for next day
            self?.scheduleMidnightReset()
        }
    }
}
