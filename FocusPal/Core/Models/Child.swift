//
//  Child.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing a child profile in the app.
/// Each child has their own activities, categories, time goals, and achievements.
struct Child: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var age: Int
    var avatarId: String
    var themeColor: String
    var preferences: ChildPreferences
    let createdDate: Date
    var lastActiveDate: Date?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        avatarId: String = "avatar_default",
        themeColor: String = "blue",
        preferences: ChildPreferences = ChildPreferences(),
        createdDate: Date = Date(),
        lastActiveDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarId = avatarId
        self.themeColor = themeColor
        self.preferences = preferences
        self.createdDate = createdDate
        self.lastActiveDate = lastActiveDate
        self.isActive = isActive
    }
}

/// Preferences specific to a child profile
struct ChildPreferences: Equatable, Hashable, Codable {
    var timerVisualization: TimerVisualizationMode = .circular
    var soundsEnabled: Bool = true
    var hapticsEnabled: Bool = true

    enum TimerVisualizationMode: String, Codable {
        case circular
        case bar
        case analog
    }
}
