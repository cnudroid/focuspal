//
//  AchievementServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the achievement service interface.
/// Manages achievement tracking, progress updates, and unlock notifications.
protocol AchievementServiceProtocol {
    /// Initialize all achievements for a child
    /// Creates achievement records if they don't exist
    func initializeAchievements(for child: Child) async throws

    /// Record a timer completion and check for achievement unlocks
    /// Returns newly unlocked achievements
    func recordTimerCompletion(for child: Child) async throws -> [Achievement]

    /// Record a streak and check for streak-based achievement unlocks
    /// - Parameter days: Number of consecutive days in the streak
    /// Returns newly unlocked achievements
    func recordStreak(days: Int, for child: Child) async throws -> [Achievement]

    /// Record time spent in a category and check for category-based achievements
    /// - Parameters:
    ///   - minutes: Duration in minutes
    ///   - category: The category being tracked
    /// Returns newly unlocked achievements
    func recordCategoryTime(minutes: Int, category: Category, for child: Child) async throws -> [Achievement]

    /// Record a balanced week and check for balance achievements
    /// - Parameter balancedDays: Number of balanced days in the week
    /// Returns newly unlocked achievements
    func recordBalancedWeek(balancedDays: Int, for child: Child) async throws -> [Achievement]

    /// Record an activity time and check for time-based achievements (e.g., Early Bird)
    /// - Parameter startTime: The start time of the activity
    /// Returns newly unlocked achievements
    func recordActivityTime(startTime: Date, for child: Child) async throws -> [Achievement]

    /// Fetch all achievements for a child
    func fetchAllAchievements(for child: Child) async throws -> [Achievement]

    /// Fetch unlocked achievements for a child
    func fetchUnlockedAchievements(for child: Child) async throws -> [Achievement]

    /// Fetch locked achievements for a child
    func fetchLockedAchievements(for child: Child) async throws -> [Achievement]
}
