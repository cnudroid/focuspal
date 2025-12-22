//
//  TimeGoal.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing a time goal for a category.
/// Time goals define recommended daily duration limits for activities.
struct TimeGoal: Identifiable, Equatable, Hashable {
    let id: UUID
    let categoryId: UUID
    let childId: UUID
    var recommendedMinutes: Int
    var warningThreshold: Int  // Percentage (e.g., 80 = 80%)
    var isActive: Bool
    let createdDate: Date

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        childId: UUID,
        recommendedMinutes: Int,
        warningThreshold: Int = 80,
        isActive: Bool = true,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.categoryId = categoryId
        self.childId = childId
        self.recommendedMinutes = recommendedMinutes
        self.warningThreshold = warningThreshold
        self.isActive = isActive
        self.createdDate = createdDate
    }

    /// Check if the given duration triggers a warning
    func shouldWarn(currentMinutes: Int) -> Bool {
        let threshold = Double(recommendedMinutes) * Double(warningThreshold) / 100.0
        return Double(currentMinutes) >= threshold
    }

    /// Check if the goal has been exceeded
    func isExceeded(currentMinutes: Int) -> Bool {
        currentMinutes >= recommendedMinutes
    }

    /// Calculate progress percentage (capped at 100)
    func progressPercentage(currentMinutes: Int) -> Double {
        min(Double(currentMinutes) / Double(recommendedMinutes) * 100, 100)
    }
}
