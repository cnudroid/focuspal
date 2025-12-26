//
//  AnalyticsService+Notifications.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Extension to AnalyticsService for notification integration
extension AnalyticsService {

    /// Check and send goal notifications based on daily usage
    /// Call this method after logging a new activity to check if goal thresholds are crossed
    func checkAndNotifyGoalStatus(
        for child: Child,
        category: Category,
        notificationService: NotificationServiceProtocol
    ) async {
        // Get daily aggregates for the category
        let today = Date()
        guard let aggregate = try? await activityService.calculateDailyAggregates(for: child, date: today)
            .first(where: { $0.category.id == category.id }) else {
            return
        }

        // Use recommended duration as the goal (converted to minutes)
        let goalMinutes = category.durationMinutes
        guard goalMinutes > 0 else {
            return
        }

        let timeUsed = aggregate.totalMinutes
        let percentageUsed = Double(timeUsed) / Double(goalMinutes)

        // Send notifications based on usage percentage
        if timeUsed > goalMinutes {
            // Goal exceeded - only notify once per day
            notificationService.scheduleGoalExceededWarning(
                category: category.name,
                timeUsed: timeUsed,
                goalTime: goalMinutes
            )
        } else if percentageUsed >= 0.9 {
            // Approaching goal (90% or more)
            notificationService.scheduleGoalApproachingWarning(
                category: category.name,
                timeUsed: timeUsed,
                goalTime: goalMinutes
            )
        }
    }

    /// Check streak status and send appropriate notifications
    /// Call this method daily or when a new activity is logged
    func checkAndNotifyStreakStatus(
        for child: Child,
        currentStreak: Int,
        previousStreak: Int,
        notificationService: NotificationServiceProtocol
    ) {
        // Celebrate milestone streaks
        if currentStreak > 0 && currentStreak != previousStreak {
            // Check if current streak is a milestone (3, 7, 30 days)
            if currentStreak == 3 || currentStreak == 7 || currentStreak == 30 {
                notificationService.scheduleStreakCelebration(
                    streakDays: currentStreak,
                    childName: child.name
                )
            }
        }

        // Notify if streak ended
        if currentStreak == 0 && previousStreak > 0 {
            notificationService.scheduleStreakEndedNotification(
                previousStreak: previousStreak,
                childName: child.name
            )
        }

        // Schedule reminder if at risk of losing streak (hasn't logged today)
        if currentStreak > 0 {
            // Schedule reminder for 7 PM if no activity logged today
            let reminderTime = DateComponents(hour: 19, minute: 0)
            notificationService.scheduleStreakReminder(
                streakDays: currentStreak,
                childName: child.name,
                at: reminderTime
            )
        }
    }

    /// Setup daily goal reminder for a child
    /// Call this during onboarding or when user enables notifications
    func setupDailyReminder(
        for child: Child,
        at time: DateComponents,
        notificationService: NotificationServiceProtocol
    ) {
        notificationService.scheduleDailyGoalReminder(
            at: time,
            childName: child.name
        )
    }
}
