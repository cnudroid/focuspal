//
//  Reward.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Defines the reward tiers that can be earned based on weekly points
enum RewardTier: String, CaseIterable, Codable {
    case bronze
    case silver
    case gold
    case platinum

    /// Display name for the tier
    var name: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        }
    }

    /// Points required to reach this tier
    var pointsRequired: Int {
        switch self {
        case .bronze: return 100
        case .silver: return 250
        case .gold: return 500
        case .platinum: return 1000
        }
    }

    /// Emoji representation of the tier
    var emoji: String {
        switch self {
        case .bronze: return "\u{1F949}"  // Bronze medal
        case .silver: return "\u{1F948}"  // Silver medal
        case .gold: return "\u{1F947}"    // Gold medal
        case .platinum: return "\u{1F48E}" // Gem stone (diamond)
        }
    }

    /// Hex color for the tier
    var colorHex: String {
        switch self {
        case .bronze: return "#CD7F32"
        case .silver: return "#C0C0C0"
        case .gold: return "#FFD700"
        case .platinum: return "#E5E4E2"
        }
    }

    /// Description of what the tier represents
    var description: String {
        switch self {
        case .bronze: return "Great start! Keep building your focus habits."
        case .silver: return "Impressive focus! You're developing strong habits."
        case .gold: return "Outstanding achievement! Your dedication is shining."
        case .platinum: return "Elite performer! You've mastered the art of focus."
        }
    }

    /// Returns all tiers sorted by points required (ascending)
    static var sortedByPoints: [RewardTier] {
        allCases.sorted { $0.pointsRequired < $1.pointsRequired }
    }

    /// Calculate which tier corresponds to a given point total
    /// - Parameter points: The number of points earned
    /// - Returns: The highest tier achieved, or nil if below bronze
    static func tier(for points: Int) -> RewardTier? {
        sortedByPoints.reversed().first { points >= $0.pointsRequired }
    }

    /// Get the next tier after this one
    /// - Returns: The next tier, or nil if already at platinum
    var nextTier: RewardTier? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return .platinum
        case .platinum: return nil
        }
    }
}

/// Domain model representing a weekly reward earned by a child
struct WeeklyReward: Identifiable, Equatable, Hashable {
    let id: UUID
    let childId: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    var totalPoints: Int
    var tier: RewardTier?
    var isRedeemed: Bool
    var redeemedDate: Date?

    init(
        id: UUID = UUID(),
        childId: UUID,
        weekStartDate: Date,
        weekEndDate: Date,
        totalPoints: Int = 0,
        tier: RewardTier? = nil,
        isRedeemed: Bool = false,
        redeemedDate: Date? = nil
    ) {
        self.id = id
        self.childId = childId
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalPoints = totalPoints
        self.tier = tier
        self.isRedeemed = isRedeemed
        self.redeemedDate = redeemedDate
    }

    /// Whether this reward has a tier (earned at least bronze)
    var hasTier: Bool {
        tier != nil
    }

    /// Points needed to reach the next tier
    var pointsToNextTier: Int? {
        if let currentTier = tier, let nextTier = currentTier.nextTier {
            return max(0, nextTier.pointsRequired - totalPoints)
        } else if tier == nil {
            // No tier yet, calculate points to bronze
            return max(0, RewardTier.bronze.pointsRequired - totalPoints)
        }
        return nil // Already at platinum
    }

    /// The next tier that can be achieved
    var nextTier: RewardTier? {
        if let currentTier = tier {
            return currentTier.nextTier
        }
        return .bronze
    }

    /// Progress percentage towards the next tier (0-100)
    var progressToNextTier: Double {
        guard let nextTier = nextTier else { return 100 }

        let previousThreshold: Int
        if let currentTier = tier {
            previousThreshold = currentTier.pointsRequired
        } else {
            previousThreshold = 0
        }

        let range = nextTier.pointsRequired - previousThreshold
        let progress = totalPoints - previousThreshold

        return min(Double(progress) / Double(range) * 100, 100)
    }
}

/// Tracks all-time reward history for a child
struct RewardHistory: Equatable, Hashable {
    let childId: UUID
    var totalPointsAllTime: Int
    var totalWeeksCompleted: Int
    var bronzeTiersEarned: Int
    var silverTiersEarned: Int
    var goldTiersEarned: Int
    var platinumTiersEarned: Int
    var longestStreak: Int
    var currentStreak: Int
    var lastWeekWithTier: Date?

    init(
        childId: UUID,
        totalPointsAllTime: Int = 0,
        totalWeeksCompleted: Int = 0,
        bronzeTiersEarned: Int = 0,
        silverTiersEarned: Int = 0,
        goldTiersEarned: Int = 0,
        platinumTiersEarned: Int = 0,
        longestStreak: Int = 0,
        currentStreak: Int = 0,
        lastWeekWithTier: Date? = nil
    ) {
        self.childId = childId
        self.totalPointsAllTime = totalPointsAllTime
        self.totalWeeksCompleted = totalWeeksCompleted
        self.bronzeTiersEarned = bronzeTiersEarned
        self.silverTiersEarned = silverTiersEarned
        self.goldTiersEarned = goldTiersEarned
        self.platinumTiersEarned = platinumTiersEarned
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.lastWeekWithTier = lastWeekWithTier
    }

    /// Total tiers earned across all categories
    var totalTiersEarned: Int {
        bronzeTiersEarned + silverTiersEarned + goldTiersEarned + platinumTiersEarned
    }

    /// Highest tier ever achieved
    var highestTierEarned: RewardTier? {
        if platinumTiersEarned > 0 { return .platinum }
        if goldTiersEarned > 0 { return .gold }
        if silverTiersEarned > 0 { return .silver }
        if bronzeTiersEarned > 0 { return .bronze }
        return nil
    }

    /// Count for a specific tier
    func count(for tier: RewardTier) -> Int {
        switch tier {
        case .bronze: return bronzeTiersEarned
        case .silver: return silverTiersEarned
        case .gold: return goldTiersEarned
        case .platinum: return platinumTiersEarned
        }
    }
}

// MARK: - Week Date Utilities

extension WeeklyReward {
    /// Creates a WeeklyReward for the current week (starting Monday)
    /// - Parameter childId: The child's UUID
    /// - Returns: A new WeeklyReward for the current week
    static func forCurrentWeek(childId: UUID) -> WeeklyReward {
        let (start, end) = Self.currentWeekDates()
        return WeeklyReward(
            childId: childId,
            weekStartDate: start,
            weekEndDate: end
        )
    }

    /// Get the start and end dates for the current week (Monday to Sunday)
    /// - Returns: Tuple of (weekStartDate, weekEndDate)
    static func currentWeekDates() -> (start: Date, end: Date) {
        weekDates(for: Date())
    }

    /// Get the start and end dates for the week containing the given date
    /// - Parameter date: Any date within the desired week
    /// - Returns: Tuple of (weekStartDate, weekEndDate)
    static func weekDates(for date: Date) -> (start: Date, end: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2

        // Get the start of the week (Monday at 00:00:00)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            // Fallback: return the date itself
            return (date, date)
        }

        let weekStart = weekInterval.start

        // End of week is Sunday at 23:59:59
        let weekEnd = calendar.date(byAdding: .second, value: -1, to: weekInterval.end) ?? weekInterval.end

        return (weekStart, weekEnd)
    }

    /// Check if a date falls within this reward's week
    /// - Parameter date: The date to check
    /// - Returns: true if the date is within the week
    func contains(date: Date) -> Bool {
        date >= weekStartDate && date <= weekEndDate
    }

    /// Check if this is the current week
    var isCurrentWeek: Bool {
        contains(date: Date())
    }
}
