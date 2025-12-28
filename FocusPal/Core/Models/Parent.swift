//
//  Parent.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing a parent user in the app.
/// Parents can manage multiple child profiles and receive notifications about their activities.
struct Parent: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var name: String
    var email: String
    let createdDate: Date
    var lastLoginDate: Date?
    var notificationPreferences: ParentNotificationPreferences

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        createdDate: Date = Date(),
        lastLoginDate: Date? = nil,
        notificationPreferences: ParentNotificationPreferences = ParentNotificationPreferences()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.createdDate = createdDate
        self.lastLoginDate = lastLoginDate
        self.notificationPreferences = notificationPreferences
    }
}

/// Notification preferences for a parent user
struct ParentNotificationPreferences: Equatable, Hashable, Codable {
    /// Whether weekly email reports are enabled
    var weeklyEmailEnabled: Bool

    /// Day of week for weekly email (1=Sunday, 2=Monday, ..., 7=Saturday)
    var weeklyEmailDay: Int

    /// Hour of day for weekly email (0-23, representing the hour in 24-hour format)
    var weeklyEmailTime: Int

    /// Whether to receive alerts when children earn achievements
    var achievementAlertsEnabled: Bool

    init(
        weeklyEmailEnabled: Bool = true,
        weeklyEmailDay: Int = 1,
        weeklyEmailTime: Int = 9,
        achievementAlertsEnabled: Bool = true
    ) {
        self.weeklyEmailEnabled = weeklyEmailEnabled
        self.weeklyEmailDay = max(1, min(7, weeklyEmailDay))
        self.weeklyEmailTime = max(0, min(23, weeklyEmailTime))
        self.achievementAlertsEnabled = achievementAlertsEnabled
    }
}
