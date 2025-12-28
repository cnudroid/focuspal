//
//  ChildPoints.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Represents the reasons for point transactions
enum PointsReason: String, CaseIterable, Codable {
    case activityComplete = "activity_complete"
    case activityIncomplete = "activity_incomplete"
    case earlyFinishBonus = "early_finish_bonus"
    case beatAverageBonus = "beat_average_bonus"
    case threeStrikePenalty = "three_strike_penalty"
    case weeklyReward = "weekly_reward"
    case achievementUnlock = "achievement_unlock"

    var displayName: String {
        switch self {
        case .activityComplete: return "Activity Completed"
        case .activityIncomplete: return "Activity Incomplete"
        case .earlyFinishBonus: return "Early Finish Bonus"
        case .beatAverageBonus: return "Beat Average Bonus"
        case .threeStrikePenalty: return "Three Strike Penalty"
        case .weeklyReward: return "Weekly Reward"
        case .achievementUnlock: return "Achievement Unlocked"
        }
    }

    var iconName: String {
        switch self {
        case .activityComplete: return "checkmark.circle.fill"
        case .activityIncomplete: return "xmark.circle.fill"
        case .earlyFinishBonus: return "clock.badge.checkmark.fill"
        case .beatAverageBonus: return "chart.line.uptrend.xyaxis"
        case .threeStrikePenalty: return "exclamationmark.triangle.fill"
        case .weeklyReward: return "star.circle.fill"
        case .achievementUnlock: return "trophy.fill"
        }
    }
}

/// Domain model representing a child's daily points summary
struct ChildPoints: Identifiable, Equatable, Hashable {
    let id: UUID
    let childId: UUID
    let date: Date
    var pointsEarned: Int
    var pointsDeducted: Int
    var bonusPoints: Int

    /// Computed property for net total points for the day
    var totalPoints: Int {
        pointsEarned + bonusPoints - pointsDeducted
    }

    init(
        id: UUID = UUID(),
        childId: UUID,
        date: Date = Date(),
        pointsEarned: Int = 0,
        pointsDeducted: Int = 0,
        bonusPoints: Int = 0
    ) {
        self.id = id
        self.childId = childId
        self.date = date
        self.pointsEarned = pointsEarned
        self.pointsDeducted = pointsDeducted
        self.bonusPoints = bonusPoints
    }

    /// Creates a deterministic UUID from childId and date
    /// This ensures the same child/date combination always has the same UUID
    static func deterministicId(childId: UUID, date: Date) -> UUID {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dateString = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        let combined = "\(childId.uuidString)-points-\(dateString)"

        let hash = combined.utf8.reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            for i in 0..<16 {
                result[i] = result[i] &+ byte &+ UInt8(i)
            }
        }

        // Set version 4 (random) bits to make it a valid UUID format
        var bytes = hash
        bytes[6] = (bytes[6] & 0x0F) | 0x40  // Version 4
        bytes[8] = (bytes[8] & 0x3F) | 0x80  // Variant

        let uuid = NSUUID(uuidBytes: bytes) as UUID
        return uuid
    }
}

/// Domain model representing an individual point transaction
struct PointsTransaction: Identifiable, Equatable, Hashable {
    let id: UUID
    let childId: UUID
    let activityId: UUID?
    let amount: Int
    let reason: PointsReason
    let timestamp: Date

    init(
        id: UUID = UUID(),
        childId: UUID,
        activityId: UUID? = nil,
        amount: Int,
        reason: PointsReason,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.activityId = activityId
        self.amount = amount
        self.reason = reason
        self.timestamp = timestamp
    }

    /// Whether this transaction adds or removes points
    var isPositive: Bool {
        amount > 0
    }

    /// Absolute value of the amount for display purposes
    var absoluteAmount: Int {
        abs(amount)
    }
}
