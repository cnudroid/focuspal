//
//  Achievement.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing an achievement/badge that can be earned.
struct Achievement: Identifiable, Equatable, Hashable {
    let id: UUID
    let achievementTypeId: String
    let childId: UUID
    var unlockedDate: Date?
    var progress: Int
    var targetValue: Int

    var isUnlocked: Bool {
        unlockedDate != nil
    }

    var progressPercentage: Double {
        min(Double(progress) / Double(targetValue) * 100, 100)
    }

    init(
        id: UUID = UUID(),
        achievementTypeId: String,
        childId: UUID,
        unlockedDate: Date? = nil,
        progress: Int = 0,
        targetValue: Int
    ) {
        self.id = id
        self.achievementTypeId = achievementTypeId
        self.childId = childId
        self.unlockedDate = unlockedDate
        self.progress = progress
        self.targetValue = targetValue
    }
}

/// Defines all available achievement types in the app
enum AchievementType: String, CaseIterable {
    case streak3Day = "streak_3day"
    case streak7Day = "streak_7day"
    case streak30Day = "streak_30day"
    case homeworkHero = "homework_hero"
    case readingChampion = "reading_champion"
    case balanceMaster = "balance_master"
    case earlyBird = "early_bird"
    case firstTimer = "first_timer"

    var name: String {
        switch self {
        case .streak3Day: return "3-Day Streak"
        case .streak7Day: return "Week Warrior"
        case .streak30Day: return "Monthly Master"
        case .homeworkHero: return "Homework Hero"
        case .readingChampion: return "Reading Champion"
        case .balanceMaster: return "Balance Master"
        case .earlyBird: return "Early Bird"
        case .firstTimer: return "First Timer"
        }
    }

    var description: String {
        switch self {
        case .streak3Day: return "Log activities for 3 days in a row"
        case .streak7Day: return "Log activities for 7 days in a row"
        case .streak30Day: return "Log activities for 30 days in a row"
        case .homeworkHero: return "Complete 10 hours of homework"
        case .readingChampion: return "Read for 20 hours total"
        case .balanceMaster: return "Stay balanced for a week"
        case .earlyBird: return "Start logging before 8 AM"
        case .firstTimer: return "Complete your first timed activity"
        }
    }

    var iconName: String {
        switch self {
        case .streak3Day: return "flame.fill"
        case .streak7Day: return "flame.circle.fill"
        case .streak30Day: return "star.circle.fill"
        case .homeworkHero: return "book.circle.fill"
        case .readingChampion: return "text.book.closed.fill"
        case .balanceMaster: return "scale.3d"
        case .earlyBird: return "sunrise.fill"
        case .firstTimer: return "timer.circle.fill"
        }
    }

    var emoji: String {
        switch self {
        case .firstTimer: return "🎯"
        case .streak3Day: return "🔥"
        case .streak7Day: return "⚔️"
        case .streak30Day: return "👑"
        case .homeworkHero: return "📚"
        case .readingChampion: return "📖"
        case .balanceMaster: return "⚖️"
        case .earlyBird: return "🌅"
        }
    }

    var targetValue: Int {
        switch self {
        case .streak3Day: return 3
        case .streak7Day: return 7
        case .streak30Day: return 30
        case .homeworkHero: return 600  // minutes
        case .readingChampion: return 1200  // minutes
        case .balanceMaster: return 7
        case .earlyBird: return 1
        case .firstTimer: return 1
        }
    }
}
