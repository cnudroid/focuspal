//
//  AchievementNotificationHelperTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Tests for AchievementNotificationHelper
/// Verifies notification creation and formatting
final class AchievementNotificationHelperTests: XCTestCase {

    // MARK: - Unlock Notification Creation Tests

    func testCreateUnlockNotifications_WithSingleAchievement_CreatesNotification() {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 1
        )

        // Act
        let notifications = AchievementNotificationHelper.createUnlockNotifications(from: [achievement])

        // Assert
        XCTAssertEqual(notifications.count, 1)
        XCTAssertEqual(notifications.first?.achievement.id, achievement.id)
    }

    func testCreateUnlockNotifications_WithMultipleAchievements_CreatesMultipleNotifications() {
        // Arrange
        let achievement1 = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 1
        )
        let achievement2 = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 3
        )

        // Act
        let notifications = AchievementNotificationHelper.createUnlockNotifications(
            from: [achievement1, achievement2]
        )

        // Assert
        XCTAssertEqual(notifications.count, 2)
    }

    func testCreateUnlockNotifications_WithEmptyArray_ReturnsEmptyArray() {
        // Arrange
        let achievements: [Achievement] = []

        // Act
        let notifications = AchievementNotificationHelper.createUnlockNotifications(from: achievements)

        // Assert
        XCTAssertTrue(notifications.isEmpty)
    }

    // MARK: - Notification Content Tests

    func testUnlockNotification_FirstTimer_HasCorrectContent() {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 1
        )

        // Act
        let notification = AchievementNotificationHelper.UnlockNotification(achievement: achievement)

        // Assert
        XCTAssertEqual(notification.title, "First Timer")
        XCTAssertEqual(notification.message, "Complete your first timed activity")
        XCTAssertEqual(notification.iconName, "timer.circle.fill")
    }

    func testUnlockNotification_Streak3Day_HasCorrectContent() {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.streak3Day.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 3
        )

        // Act
        let notification = AchievementNotificationHelper.UnlockNotification(achievement: achievement)

        // Assert
        XCTAssertEqual(notification.title, "3-Day Streak")
        XCTAssertEqual(notification.message, "Log activities for 3 days in a row")
        XCTAssertEqual(notification.iconName, "flame.fill")
    }

    func testUnlockNotification_HomeworkHero_HasCorrectContent() {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.homeworkHero.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 600
        )

        // Act
        let notification = AchievementNotificationHelper.UnlockNotification(achievement: achievement)

        // Assert
        XCTAssertEqual(notification.title, "Homework Hero")
        XCTAssertEqual(notification.message, "Complete 10 hours of homework")
        XCTAssertEqual(notification.iconName, "book.circle.fill")
    }

    func testUnlockNotification_InvalidType_HasDefaultContent() {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: "invalid_type",
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 1
        )

        // Act
        let notification = AchievementNotificationHelper.UnlockNotification(achievement: achievement)

        // Assert
        XCTAssertEqual(notification.title, "Achievement Unlocked!")
        XCTAssertEqual(notification.message, "Great job!")
        XCTAssertEqual(notification.iconName, "star.fill")
    }

    // MARK: - Celebration Message Tests

    func testGetCelebrationMessage_ReturnsNonEmptyMessage() {
        // Act
        let message = AchievementNotificationHelper.getCelebrationMessage(for: .firstTimer)

        // Assert
        XCTAssertFalse(message.isEmpty)
    }

    func testGetCelebrationMessage_WithNilType_ReturnsDefaultMessage() {
        // Act
        let message = AchievementNotificationHelper.getCelebrationMessage(for: nil)

        // Assert
        XCTAssertFalse(message.isEmpty)
    }

    func testGetCelebrationMessage_ReturnsVariedMessages() {
        // Arrange
        var messages = Set<String>()

        // Act - Call multiple times to get different messages
        for _ in 0..<20 {
            let message = AchievementNotificationHelper.getCelebrationMessage(for: .firstTimer)
            messages.insert(message)
        }

        // Assert - Should have multiple different messages
        XCTAssertGreaterThan(messages.count, 1, "Should return varied celebration messages")
    }

    // MARK: - Notification Uniqueness Tests

    func testUnlockNotification_EachHasUniqueId() {
        // Arrange
        let achievement = Achievement(
            achievementTypeId: AchievementType.firstTimer.rawValue,
            childId: UUID(),
            unlockedDate: Date(),
            targetValue: 1
        )

        // Act
        let notification1 = AchievementNotificationHelper.UnlockNotification(achievement: achievement)
        let notification2 = AchievementNotificationHelper.UnlockNotification(achievement: achievement)

        // Assert
        XCTAssertNotEqual(notification1.id, notification2.id,
                         "Each notification should have a unique ID")
    }

    // MARK: - All Achievement Types Tests

    func testUnlockNotification_AllAchievementTypes_HaveValidContent() {
        // Test all achievement types have proper content

        for achievementType in AchievementType.allCases {
            // Arrange
            let achievement = Achievement(
                achievementTypeId: achievementType.rawValue,
                childId: UUID(),
                unlockedDate: Date(),
                targetValue: achievementType.targetValue
            )

            // Act
            let notification = AchievementNotificationHelper.UnlockNotification(achievement: achievement)

            // Assert
            XCTAssertFalse(notification.title.isEmpty,
                          "Title should not be empty for \(achievementType.rawValue)")
            XCTAssertFalse(notification.message.isEmpty,
                          "Message should not be empty for \(achievementType.rawValue)")
            XCTAssertFalse(notification.iconName.isEmpty,
                          "Icon name should not be empty for \(achievementType.rawValue)")
        }
    }
}
