//
//  NotificationServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the notification service interface.
/// Manages local notifications for timers, goals, and achievements.
protocol NotificationServiceProtocol {
    /// Request notification authorization from the user
    func requestAuthorization() async throws -> Bool

    /// Check current authorization status
    func checkAuthorizationStatus() async -> NotificationAuthorizationStatus

    // MARK: - Timer Notifications

    /// Schedule a notification for timer completion
    func scheduleTimerCompletion(in duration: TimeInterval, categoryName: String)

    /// Schedule a 5-minute warning notification
    func scheduleFiveMinuteWarning(in duration: TimeInterval, categoryName: String)

    /// Schedule a 1-minute warning notification
    func scheduleOneMinuteWarning(in duration: TimeInterval, categoryName: String)

    /// Cancel all timer-related notifications
    func cancelTimerNotifications()

    // MARK: - Goal Notifications

    /// Schedule a daily goal reminder at a specific time
    func scheduleDailyGoalReminder(at time: DateComponents, childName: String)

    /// Schedule a notification when a goal is exceeded
    func scheduleGoalExceededWarning(category: String, timeUsed: Int, goalTime: Int)

    /// Schedule a notification when approaching a goal limit (e.g., 90% of goal)
    func scheduleGoalApproachingWarning(category: String, timeUsed: Int, goalTime: Int)

    /// Schedule a warning notification when approaching time goal (legacy method)
    func scheduleTimeGoalWarning(category: String, timeUsed: Int, goalTime: Int)

    /// Schedule a notification when time goal is exceeded
    func scheduleTimeGoalExceeded(category: String, timeUsed: Int, goalTime: Int)

    // MARK: - Streak Notifications

    /// Schedule a celebration notification for achieving a streak milestone
    func scheduleStreakCelebration(streakDays: Int, childName: String)

    /// Schedule a reminder to maintain the current streak
    func scheduleStreakReminder(streakDays: Int, childName: String, at time: DateComponents)

    /// Schedule a notification when a streak ends
    func scheduleStreakEndedNotification(previousStreak: Int, childName: String)

    // MARK: - Achievement Notifications

    /// Schedule a notification for achievement unlock
    func scheduleAchievementUnlock(achievement: Achievement)

    // MARK: - Cancellation

    /// Cancel all pending notifications
    func cancelAllNotifications()

    /// Cancel specific notifications by identifier
    func cancelNotifications(withIdentifier identifier: String)
}

/// Notification authorization status
enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case provisional
}
