//
//  AchievementNotificationHelper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import UserNotifications

/// Helper for displaying achievement unlock notifications
/// Provides celebration UI and haptic feedback for newly unlocked achievements
struct AchievementNotificationHelper {

    // MARK: - Notification Data

    /// Data structure for displaying achievement unlock notification
    struct UnlockNotification: Identifiable {
        let id = UUID()
        let achievement: Achievement
        let achievementType: AchievementType?

        var title: String {
            achievementType?.name ?? "Achievement Unlocked!"
        }

        var message: String {
            achievementType?.description ?? "Great job!"
        }

        var iconName: String {
            achievementType?.iconName ?? "star.fill"
        }

        init(achievement: Achievement) {
            self.achievement = achievement
            self.achievementType = AchievementType(rawValue: achievement.achievementTypeId)
        }
    }

    // MARK: - Notification Creation

    /// Create unlock notifications from newly unlocked achievements
    /// - Parameter achievements: Array of newly unlocked achievements
    /// - Returns: Array of notifications ready to display
    static func createUnlockNotifications(from achievements: [Achievement]) -> [UnlockNotification] {
        return achievements.map { UnlockNotification(achievement: $0) }
    }

    // MARK: - Haptic Feedback

    /// Trigger haptic feedback for achievement unlock
    /// Uses success haptic pattern for achievement celebrations
    @available(iOS 13.0, *)
    static func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Local Notification

    /// Schedule a local notification for achievement unlock
    /// - Parameters:
    ///   - achievement: The unlocked achievement
    ///   - childName: Name of the child who unlocked it
    static func scheduleLocalNotification(for achievement: Achievement, childName: String) async {
        let content = UNMutableNotificationContent()

        if let achievementType = AchievementType(rawValue: achievement.achievementTypeId) {
            content.title = "Achievement Unlocked!"
            content.body = "\(childName) earned '\(achievementType.name)': \(achievementType.description)"
            content.sound = .default
            content.categoryIdentifier = "ACHIEVEMENT_UNLOCK"

            // Add custom data
            content.userInfo = [
                "achievementId": achievement.id.uuidString,
                "achievementTypeId": achievement.achievementTypeId,
                "childId": achievement.childId.uuidString
            ]

            // Create trigger (immediate)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            // Create request
            let request = UNNotificationRequest(
                identifier: achievement.id.uuidString,
                content: content,
                trigger: trigger
            )

            // Schedule notification
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Error scheduling achievement notification: \(error)")
            }
        }
    }

    // MARK: - Celebration Messages

    /// Get a celebratory message for achievement unlock
    /// - Parameter achievementType: The type of achievement unlocked
    /// - Returns: A random celebration message
    static func getCelebrationMessage(for achievementType: AchievementType?) -> String {
        let messages: [String] = [
            "Awesome job!",
            "You did it!",
            "Amazing work!",
            "Keep it up!",
            "Fantastic!",
            "Way to go!",
            "Excellent!",
            "Superstar!"
        ]

        return messages.randomElement() ?? "Great work!"
    }
}

// MARK: - iOS Compatibility Shim

#if canImport(UIKit)
import UIKit
#endif
