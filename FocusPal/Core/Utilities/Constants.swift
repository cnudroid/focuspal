//
//  Constants.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// App-wide constants and configuration values.
enum Constants {

    // MARK: - App Info

    enum App {
        static let name = "FocusPal"
        static let bundleIdentifier = "com.focuspal.dev"
        static let appStoreId = ""  // To be set after App Store release
    }

    // MARK: - Timer Defaults

    enum Timer {
        static let defaultDuration: TimeInterval = 25 * 60  // 25 minutes
        static let minimumDuration: TimeInterval = 1 * 60   // 1 minute
        static let maximumDuration: TimeInterval = 120 * 60 // 2 hours
        static let tickInterval: TimeInterval = 0.1
    }

    // MARK: - Age Ranges

    enum Age {
        static let minimum = 4
        static let maximum = 16
        static let `default` = 8
    }

    // MARK: - Storage Keys

    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let activeChildId = "activeChildId"
        static let parentPIN = "parentPIN"
        static let useBiometrics = "useBiometrics"
        static let soundsEnabled = "soundsEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let lastSyncDate = "lastSyncDate"
    }

    // MARK: - Notification Identifiers

    enum NotificationIds {
        static let timerComplete = "timer_completion"
        static let timeGoalWarning = "time_goal_warning"
        static let achievementUnlock = "achievement_unlock"
        static let dailyReminder = "daily_reminder"
    }

    // MARK: - Animation

    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.6
    }

    // MARK: - Limits

    enum Limits {
        static let maxChildren = 10
        static let maxCategories = 50
        static let maxActivitiesPerDay = 100
        static let nameMaxLength = 50
        static let notesMaxLength = 500
    }

    // MARK: - CloudKit

    enum CloudKit {
        static let containerIdentifier = "iCloud.com.focuspal.dev"
        static let zoneId = "FocusPalZone"
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let timerLabel = "Timer"
        static let playButtonLabel = "Start timer"
        static let pauseButtonLabel = "Pause timer"
        static let stopButtonLabel = "Stop timer"
    }
}
