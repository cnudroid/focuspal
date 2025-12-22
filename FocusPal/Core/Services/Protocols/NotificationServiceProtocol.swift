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

    /// Schedule a notification for timer completion
    func scheduleTimerCompletion(in duration: TimeInterval, categoryName: String)

    /// Schedule a warning notification when approaching time goal
    func scheduleTimeGoalWarning(category: String, timeUsed: Int, goalTime: Int)

    /// Schedule a notification for achievement unlock
    func scheduleAchievementUnlock(achievement: Achievement)

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
