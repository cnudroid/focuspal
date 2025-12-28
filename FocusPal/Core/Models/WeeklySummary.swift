//
//  WeeklySummary.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Represents aggregated weekly activity data for a child
/// Used for generating weekly email reports for parents
struct WeeklySummary {
    let childName: String
    let weekStartDate: Date
    let weekEndDate: Date
    let totalActivities: Int
    let completedActivities: Int
    let incompleteActivities: Int
    let totalMinutes: Int
    let pointsEarned: Int
    let pointsDeducted: Int
    let netPoints: Int
    let currentTier: RewardTier?
    let topCategories: [(categoryName: String, minutes: Int)]
    let achievementsUnlocked: Int
    let streak: Int

    init(
        childName: String,
        weekStartDate: Date,
        weekEndDate: Date,
        totalActivities: Int,
        completedActivities: Int,
        incompleteActivities: Int,
        totalMinutes: Int,
        pointsEarned: Int,
        pointsDeducted: Int,
        netPoints: Int,
        currentTier: RewardTier? = nil,
        topCategories: [(categoryName: String, minutes: Int)] = [],
        achievementsUnlocked: Int = 0,
        streak: Int = 0
    ) {
        self.childName = childName
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalActivities = totalActivities
        self.completedActivities = completedActivities
        self.incompleteActivities = incompleteActivities
        self.totalMinutes = totalMinutes
        self.pointsEarned = pointsEarned
        self.pointsDeducted = pointsDeducted
        self.netPoints = netPoints
        self.currentTier = currentTier
        self.topCategories = topCategories
        self.achievementsUnlocked = achievementsUnlocked
        self.streak = streak
    }

    /// Completion rate as a percentage (0-100)
    var completionRate: Double {
        guard totalActivities > 0 else { return 0 }
        return Double(completedActivities) / Double(totalActivities) * 100
    }

    /// Total hours rounded to 1 decimal place
    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    /// Average minutes per activity
    var averageMinutesPerActivity: Int {
        guard totalActivities > 0 else { return 0 }
        return totalMinutes / totalActivities
    }

    /// Whether the child earned any tier this week
    var hasEarnedTier: Bool {
        currentTier != nil
    }
}

// MARK: - Equatable & Hashable Conformance

extension WeeklySummary: Equatable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(childName)
        hasher.combine(weekStartDate)
        hasher.combine(weekEndDate)
        hasher.combine(totalActivities)
        hasher.combine(completedActivities)
        hasher.combine(incompleteActivities)
        hasher.combine(totalMinutes)
        hasher.combine(pointsEarned)
        hasher.combine(pointsDeducted)
        hasher.combine(netPoints)
        hasher.combine(currentTier)
        hasher.combine(achievementsUnlocked)
        hasher.combine(streak)
        // Note: topCategories is compared separately in ==
    }

    static func == (lhs: WeeklySummary, rhs: WeeklySummary) -> Bool {
        lhs.childName == rhs.childName &&
        lhs.weekStartDate == rhs.weekStartDate &&
        lhs.weekEndDate == rhs.weekEndDate &&
        lhs.totalActivities == rhs.totalActivities &&
        lhs.completedActivities == rhs.completedActivities &&
        lhs.incompleteActivities == rhs.incompleteActivities &&
        lhs.totalMinutes == rhs.totalMinutes &&
        lhs.pointsEarned == rhs.pointsEarned &&
        lhs.pointsDeducted == rhs.pointsDeducted &&
        lhs.netPoints == rhs.netPoints &&
        lhs.currentTier == rhs.currentTier &&
        lhs.achievementsUnlocked == rhs.achievementsUnlocked &&
        lhs.streak == rhs.streak &&
        areTopCategoriesEqual(lhs.topCategories, rhs.topCategories)
    }

    private static func areTopCategoriesEqual(
        _ lhs: [(categoryName: String, minutes: Int)],
        _ rhs: [(categoryName: String, minutes: Int)]
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (index, leftItem) in lhs.enumerated() {
            let rightItem = rhs[index]
            if leftItem.categoryName != rightItem.categoryName || leftItem.minutes != rightItem.minutes {
                return false
            }
        }
        return true
    }
}
