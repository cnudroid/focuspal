//
//  WidgetData.swift
//  FocusPal
//
//  Shared data model for home screen widgets.
//  This file is included in both main app and widget extension targets.
//

import Foundation

/// Data model for widget content - shared between app and widget extension
struct WidgetData: Codable {
    /// Current child's name
    let childName: String

    /// Current child's ID
    let childId: UUID

    /// Current streak count (consecutive days)
    let currentStreak: Int

    /// Total focus time today in minutes
    let todayTotalMinutes: Int

    /// Today's activities by category
    let todayCategories: [CategoryProgress]

    /// Top categories for quick actions (up to 3)
    let topCategories: [QuickCategory]

    /// Weekly summary (last 7 days)
    let weeklyMinutes: [Int]  // Index 0 = 6 days ago, Index 6 = today

    /// Recent activities for large widget
    let recentActivities: [RecentActivity]

    /// Total points earned
    let totalPoints: Int

    /// Active timer info (if any)
    let activeTimer: ActiveTimerInfo?

    /// Timestamp when data was last updated
    let lastUpdated: Date

    /// Default empty state
    static var empty: WidgetData {
        WidgetData(
            childName: "No Profile",
            childId: UUID(),
            currentStreak: 0,
            todayTotalMinutes: 0,
            todayCategories: [],
            topCategories: [],
            weeklyMinutes: [0, 0, 0, 0, 0, 0, 0],
            recentActivities: [],
            totalPoints: 0,
            activeTimer: nil,
            lastUpdated: Date()
        )
    }
}

/// Progress for a single category today
struct CategoryProgress: Codable, Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let minutes: Int
    let goalMinutes: Int?

    var progress: Double {
        guard let goal = goalMinutes, goal > 0 else { return 0 }
        return min(1.0, Double(minutes) / Double(goal))
    }
}

/// Category info for quick action buttons
struct QuickCategory: Codable, Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let durationMinutes: Int
}

/// Recent activity for display in large widget
struct RecentActivity: Codable, Identifiable {
    let id: UUID
    let categoryName: String
    let iconName: String
    let colorHex: String
    let durationMinutes: Int
    let completedAt: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }
}

/// Active timer information
struct ActiveTimerInfo: Codable {
    let childName: String
    let categoryName: String
    let iconName: String
    let colorHex: String
    let remainingSeconds: Int
    let totalSeconds: Int
    let isPaused: Bool

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }
}

// MARK: - WidgetData Provider Helper

extension WidgetData {
    /// Load widget data from shared UserDefaults
    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.suiteName),
              let data = defaults.data(forKey: WidgetConstants.Keys.widgetData) else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    /// Save widget data to shared UserDefaults
    func save() {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.suiteName),
              let data = try? JSONEncoder().encode(self) else {
            return
        }

        defaults.set(data, forKey: WidgetConstants.Keys.widgetData)
        defaults.set(Date(), forKey: WidgetConstants.Keys.lastUpdated)
    }
}
