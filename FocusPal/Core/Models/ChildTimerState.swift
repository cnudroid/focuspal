//
//  ChildTimerState.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Represents the persisted timer state for a specific child.
/// This allows multiple children to have concurrent timers.
struct ChildTimerState: Codable, Equatable {
    let childId: UUID
    let childName: String
    let categoryId: UUID
    let categoryName: String
    let categoryIconName: String
    let categoryColorHex: String
    let startTime: Date
    let totalDuration: TimeInterval
    let pausedDuration: TimeInterval  // Total time spent paused
    let pausedAt: Date?  // When the timer was paused (nil if running)
    let isPaused: Bool

    /// Calculate remaining time based on current date
    var remainingTime: TimeInterval {
        let elapsed = elapsedTime
        return max(0, totalDuration - elapsed)
    }

    /// Calculate elapsed time accounting for pauses
    var elapsedTime: TimeInterval {
        if isPaused, let pausedAt = pausedAt {
            // Timer is paused - calculate time until it was paused
            return pausedDuration + pausedAt.timeIntervalSince(startTime)
        } else {
            // Timer is running - calculate current elapsed time
            return pausedDuration + Date().timeIntervalSince(startTime)
        }
    }

    /// Check if the timer has completed
    var isCompleted: Bool {
        remainingTime <= 0
    }

    /// Progress from 0.0 to 1.0
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return remainingTime / totalDuration
    }

    /// Create initial timer state
    static func start(
        child: Child,
        category: Category,
        duration: TimeInterval
    ) -> ChildTimerState {
        ChildTimerState(
            childId: child.id,
            childName: child.name,
            categoryId: category.id,
            categoryName: category.name,
            categoryIconName: category.iconName,
            categoryColorHex: category.colorHex,
            startTime: Date(),
            totalDuration: duration,
            pausedDuration: 0,
            pausedAt: nil,
            isPaused: false
        )
    }

    /// Create a paused version of this state
    func paused() -> ChildTimerState {
        guard !isPaused else { return self }
        return ChildTimerState(
            childId: childId,
            childName: childName,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryIconName: categoryIconName,
            categoryColorHex: categoryColorHex,
            startTime: startTime,
            totalDuration: totalDuration,
            pausedDuration: pausedDuration,
            pausedAt: Date(),
            isPaused: true
        )
    }

    /// Create a resumed version of this state
    func resumed() -> ChildTimerState {
        guard isPaused, let pausedAt = pausedAt else { return self }
        let additionalPausedTime = Date().timeIntervalSince(pausedAt)
        return ChildTimerState(
            childId: childId,
            childName: childName,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryIconName: categoryIconName,
            categoryColorHex: categoryColorHex,
            startTime: Date(),  // Reset start time to now
            totalDuration: totalDuration,
            pausedDuration: pausedDuration + pausedAt.timeIntervalSince(startTime),  // Accumulate paused duration
            pausedAt: nil,
            isPaused: false
        )
    }

    /// Add time to the timer
    func withAddedTime(_ time: TimeInterval) -> ChildTimerState {
        ChildTimerState(
            childId: childId,
            childName: childName,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryIconName: categoryIconName,
            categoryColorHex: categoryColorHex,
            startTime: startTime,
            totalDuration: totalDuration + time,
            pausedDuration: pausedDuration,
            pausedAt: pausedAt,
            isPaused: isPaused
        )
    }
}
