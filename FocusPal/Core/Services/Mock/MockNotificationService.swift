//
//  MockNotificationService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of NotificationServiceProtocol for testing and previews
class MockNotificationService: NotificationServiceProtocol {

    // MARK: - Properties

    var authorizationGranted = true
    var authorizationStatus: NotificationAuthorizationStatus = .authorized

    // Tracking for verification in tests
    var requestAuthorizationCalled = false
    var scheduledTimerCompletions: [(duration: TimeInterval, categoryName: String)] = []
    var scheduledFiveMinuteWarnings: [(duration: TimeInterval, categoryName: String)] = []
    var scheduledOneMinuteWarnings: [(duration: TimeInterval, categoryName: String)] = []
    var scheduledDailyReminders: [(time: DateComponents, childName: String)] = []
    var scheduledGoalExceededWarnings: [(category: String, timeUsed: Int, goalTime: Int)] = []
    var scheduledGoalApproachingWarnings: [(category: String, timeUsed: Int, goalTime: Int)] = []
    var scheduledStreakCelebrations: [(streakDays: Int, childName: String)] = []
    var scheduledStreakReminders: [(streakDays: Int, childName: String, time: DateComponents)] = []
    var scheduledStreakEndedNotifications: [(previousStreak: Int, childName: String)] = []
    var scheduledAchievements: [Achievement] = []
    var cancelledIdentifiers: [String] = []
    var allNotificationsCancelled = false
    var timerNotificationsCancelled = false

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCalled = true
        return authorizationGranted
    }

    func checkAuthorizationStatus() async -> NotificationAuthorizationStatus {
        return authorizationStatus
    }

    // MARK: - Timer Notifications

    func scheduleTimerCompletion(in duration: TimeInterval, categoryName: String) {
        scheduledTimerCompletions.append((duration: duration, categoryName: categoryName))
    }

    func scheduleFiveMinuteWarning(in duration: TimeInterval, categoryName: String) {
        scheduledFiveMinuteWarnings.append((duration: duration, categoryName: categoryName))
    }

    func scheduleOneMinuteWarning(in duration: TimeInterval, categoryName: String) {
        scheduledOneMinuteWarnings.append((duration: duration, categoryName: categoryName))
    }

    func cancelTimerNotifications() {
        timerNotificationsCancelled = true
        scheduledTimerCompletions.removeAll()
        scheduledFiveMinuteWarnings.removeAll()
        scheduledOneMinuteWarnings.removeAll()
    }

    // MARK: - Goal Notifications

    func scheduleDailyGoalReminder(at time: DateComponents, childName: String) {
        scheduledDailyReminders.append((time: time, childName: childName))
    }

    func scheduleGoalExceededWarning(category: String, timeUsed: Int, goalTime: Int) {
        scheduledGoalExceededWarnings.append((category: category, timeUsed: timeUsed, goalTime: goalTime))
    }

    func scheduleGoalApproachingWarning(category: String, timeUsed: Int, goalTime: Int) {
        scheduledGoalApproachingWarnings.append((category: category, timeUsed: timeUsed, goalTime: goalTime))
    }

    func scheduleTimeGoalWarning(category: String, timeUsed: Int, goalTime: Int) {
        // Legacy method - delegate to goal approaching
        scheduleGoalApproachingWarning(category: category, timeUsed: timeUsed, goalTime: goalTime)
    }

    func scheduleTimeGoalExceeded(category: String, timeUsed: Int, goalTime: Int) {
        // Delegate to goal exceeded
        scheduleGoalExceededWarning(category: category, timeUsed: timeUsed, goalTime: goalTime)
    }

    // MARK: - Streak Notifications

    func scheduleStreakCelebration(streakDays: Int, childName: String) {
        scheduledStreakCelebrations.append((streakDays: streakDays, childName: childName))
    }

    func scheduleStreakReminder(streakDays: Int, childName: String, at time: DateComponents) {
        scheduledStreakReminders.append((streakDays: streakDays, childName: childName, time: time))
    }

    func scheduleStreakEndedNotification(previousStreak: Int, childName: String) {
        scheduledStreakEndedNotifications.append((previousStreak: previousStreak, childName: childName))
    }

    // MARK: - Achievement Notifications

    func scheduleAchievementUnlock(achievement: Achievement) {
        scheduledAchievements.append(achievement)
    }

    // MARK: - Cancellation

    func cancelAllNotifications() {
        allNotificationsCancelled = true
        scheduledTimerCompletions.removeAll()
        scheduledFiveMinuteWarnings.removeAll()
        scheduledOneMinuteWarnings.removeAll()
        scheduledDailyReminders.removeAll()
        scheduledGoalExceededWarnings.removeAll()
        scheduledGoalApproachingWarnings.removeAll()
        scheduledStreakCelebrations.removeAll()
        scheduledStreakReminders.removeAll()
        scheduledStreakEndedNotifications.removeAll()
        scheduledAchievements.removeAll()
    }

    func cancelNotifications(withIdentifier identifier: String) {
        cancelledIdentifiers.append(identifier)
    }

    // MARK: - Test Helpers

    func reset() {
        requestAuthorizationCalled = false
        scheduledTimerCompletions.removeAll()
        scheduledFiveMinuteWarnings.removeAll()
        scheduledOneMinuteWarnings.removeAll()
        scheduledDailyReminders.removeAll()
        scheduledGoalExceededWarnings.removeAll()
        scheduledGoalApproachingWarnings.removeAll()
        scheduledStreakCelebrations.removeAll()
        scheduledStreakReminders.removeAll()
        scheduledStreakEndedNotifications.removeAll()
        scheduledAchievements.removeAll()
        cancelledIdentifiers.removeAll()
        allNotificationsCancelled = false
        timerNotificationsCancelled = false
    }
}
