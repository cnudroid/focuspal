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

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - NotificationServiceProtocol

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

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling timer notification: \(error)")
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

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling goal warning: \(error)")
            }
        }
    }

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

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling achievement notification: \(error)")
            }
        }
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotifications(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
