//
//  FocusPalTimerAttributes.swift
//  FocusPal
//
//  Created by FocusPal Team
//
//  ActivityAttributes model for Live Activities timer display on lock screen
//  and Dynamic Island. This file must be included in both the main app target
//  and the widget extension target.
//

import ActivityKit
import SwiftUI

/// Defines the data model for FocusPal timer Live Activities.
/// Used for displaying timer countdown on lock screen and Dynamic Island.
/// Note: The struct name must match exactly between app and widget extension.
struct FocusPalTimerAttributes: ActivityAttributes {

    // MARK: - Static Content (Set at activity start, never changes)

    /// Child's name (e.g., "Emma")
    let childName: String

    /// Category name (e.g., "Homework")
    let categoryName: String

    /// SF Symbol name for category icon (e.g., "book.fill")
    let categoryIconName: String

    /// Hex color for the category (e.g., "#4A90D9")
    let categoryColorHex: String

    /// Child ID for tracking
    let childId: UUID

    /// Total duration in seconds
    let totalDuration: TimeInterval

    // MARK: - Dynamic Content State

    /// ContentState contains data that changes during the Live Activity lifecycle
    struct ContentState: Codable, Hashable {
        /// Remaining time in seconds
        let remainingTime: TimeInterval

        /// Whether the timer is paused
        let isPaused: Bool

        /// Timer end time for countdown display (using Date for automatic updates)
        let timerEndDate: Date

        /// Total duration stored for progress calculation
        let totalDuration: TimeInterval

        /// Progress from 0.0 to 1.0 (1.0 = just started, 0.0 = completed)
        var progress: Double {
            guard totalDuration > 0 else { return 0 }
            return remainingTime / totalDuration
        }

        /// Formatted remaining time string (mm:ss)
        var formattedTime: String {
            let totalSeconds = Int(remainingTime)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        /// Formatted remaining time string for longer durations (h:mm:ss)
        var formattedTimeLong: String {
            let totalSeconds = Int(remainingTime)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
}

// MARK: - Convenience Initializers (Main App Only)

#if !WIDGET_EXTENSION
extension FocusPalTimerAttributes {
    /// Create attributes from a ChildTimerState
    init(from state: ChildTimerState) {
        self.childName = state.childName
        self.categoryName = state.categoryName
        self.categoryIconName = state.categoryIconName
        self.categoryColorHex = state.categoryColorHex
        self.childId = state.childId
        self.totalDuration = state.totalDuration
    }
}

extension FocusPalTimerAttributes.ContentState {
    /// Create content state from a ChildTimerState
    init(from state: ChildTimerState) {
        self.remainingTime = state.remainingTime
        self.isPaused = state.isPaused
        self.totalDuration = state.totalDuration

        // Calculate end date for auto-updating countdown
        // If paused, use current date (timer frozen)
        // If running, calculate when timer will end
        if state.isPaused {
            self.timerEndDate = Date()
        } else {
            self.timerEndDate = Date().addingTimeInterval(state.remainingTime)
        }
    }
}
#endif
