//
//  NotificationService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import UserNotifications

/// Concrete implementation of the notification service.
/// Manages local notifications for the app.
class NotificationService: NotificationServiceProtocol {

    // MARK: - Properties

    private let notificationCenter: UNUserNotificationCenterProtocol

    // MARK: - Initialization

    init(notificationCenter: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            return granted
        } catch {
            throw error
        }
    }

    func checkAuthorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        @unknown default:
            return .notDetermined
        }
    }

    // MARK: - Timer Notifications

    func scheduleTimerCompletion(in duration: TimeInterval, categoryName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "Your \(categoryName) session has ended."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("timer-complete.wav"))
        content.categoryIdentifier = "TIMER_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)

        let request = UNNotificationRequest(
            identifier: "timer_completion",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling timer notification: \(error)")
            }
        }
    }

    func scheduleFiveMinuteWarning(in duration: TimeInterval, categoryName: String) {
        // Only schedule if duration is greater than 5 minutes
        guard duration > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "5 Minutes Remaining"
        content.body = "Your \(categoryName) session will end in 5 minutes."
        content.sound = .default
        content.categoryIdentifier = "TIMER_WARNING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)

        let request = UNNotificationRequest(
            identifier: "timer_warning_5min",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling 5-minute warning: \(error)")
            }
        }
    }

    func scheduleOneMinuteWarning(in duration: TimeInterval, categoryName: String) {
        // Only schedule if duration is greater than 1 minute
        guard duration > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "1 Minute Remaining"
        content.body = "Your \(categoryName) session will end in 1 minute."
        content.sound = .default
        content.categoryIdentifier = "TIMER_WARNING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)

        let request = UNNotificationRequest(
            identifier: "timer_warning_1min",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling 1-minute warning: \(error)")
            }
        }
    }

    func cancelTimerNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "timer_completion",
            "timer_warning_5min",
            "timer_warning_1min"
        ])
    }

    // MARK: - Goal Notifications

    func scheduleDailyGoalReminder(at time: DateComponents, childName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Log Activities!"
        content.body = "Hi \(childName)! Don't forget to log your activities today to maintain your streak."
        content.sound = .default
        content.categoryIdentifier = "GOAL_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_goal_reminder_\(childName)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }

    func scheduleGoalExceededWarning(category: String, timeUsed: Int, goalTime: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Exceeded!"
        content.body = "You've exceeded your \(goalTime) minute goal for \(category). Time to take a break!"
        content.sound = .default
        content.categoryIdentifier = "GOAL_EXCEEDED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "goal_exceeded_\(category)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling goal exceeded warning: \(error)")
            }
        }
    }

    func scheduleGoalApproachingWarning(category: String, timeUsed: Int, goalTime: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Approaching Goal Limit"
        content.body = "You've used \(timeUsed) of \(goalTime) minutes for \(category). Almost at your goal!"
        content.sound = .default
        content.categoryIdentifier = "GOAL_APPROACHING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "goal_approaching_\(category)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling goal approaching warning: \(error)")
            }
        }
    }

    func scheduleTimeGoalWarning(category: String, timeUsed: Int, goalTime: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time Goal Warning"
        content.body = "You've used \(timeUsed) minutes of your \(goalTime) minute \(category) goal."
        content.sound = .default
        content.categoryIdentifier = "TIME_GOAL_WARNING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "time_goal_warning_\(category)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling goal warning: \(error)")
            }
        }
    }

    func scheduleTimeGoalExceeded(category: String, timeUsed: Int, goalTime: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time Goal Exceeded!"
        content.body = "You've used \(timeUsed) minutes and exceeded your \(goalTime) minute \(category) goal. Great job tracking your time!"
        content.sound = .default
        content.categoryIdentifier = "TIME_GOAL_EXCEEDED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "time_goal_exceeded_\(category)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling goal exceeded notification: \(error)")
            }
        }
    }

    // MARK: - Streak Notifications

    func scheduleStreakCelebration(streakDays: Int, childName: String) {
        let content = UNMutableNotificationContent()

        // Customize title based on streak length
        switch streakDays {
        case 3:
            content.title = "3-Day Streak!"
            content.body = "Awesome job, \(childName)! You've logged activities for 3 days in a row!"
        case 7:
            content.title = "Week Streak!"
            content.body = "Incredible, \(childName)! You've maintained a 7-day streak!"
        case 30:
            content.title = "30-Day Streak!"
            content.body = "Amazing achievement, \(childName)! A full month of consistency!"
        default:
            content.title = "\(streakDays)-Day Streak!"
            content.body = "Great work, \(childName)! Keep the momentum going!"
        }

        content.sound = UNNotificationSound(named: UNNotificationSoundName("achievement-unlock.wav"))
        content.categoryIdentifier = "STREAK_CELEBRATION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak_celebration_\(streakDays)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling streak celebration: \(error)")
            }
        }
    }

    func scheduleStreakReminder(streakDays: Int, childName: String, at time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        content.body = "You have a \(streakDays)-day streak, \(childName)! Log an activity today to keep it going."
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak_reminder_\(childName)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling streak reminder: \(error)")
            }
        }
    }

    func scheduleStreakEndedNotification(previousStreak: Int, childName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Streak Ended"
        content.body = "Your \(previousStreak)-day streak has ended, \(childName). Start a new one today!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_ENDED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak_ended_\(childName)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling streak ended notification: \(error)")
            }
        }
    }

    // MARK: - Achievement Notifications

    func scheduleAchievementUnlock(achievement: Achievement) {
        guard let type = AchievementType(rawValue: achievement.achievementTypeId) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "You earned: \(type.name)"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("achievement-unlock.wav"))
        content.categoryIdentifier = "ACHIEVEMENT_UNLOCK"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling achievement notification: \(error)")
            }
        }
    }

    // MARK: - Cancellation

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotifications(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - UNUserNotificationCenter Protocol

protocol UNUserNotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func notificationSettings() async -> UNNotificationSettings
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
}

// Extend real UNUserNotificationCenter to conform to protocol
extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return try await requestAuthorization(options: options)
    }

    func notificationSettings() async -> UNNotificationSettings {
        return await notificationSettings()
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await add(request)
    }
}
