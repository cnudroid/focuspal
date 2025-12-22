//
//  TimerMode.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Additional timer mode configurations and presets.

/// Preset timer durations for quick selection
enum TimerPreset: CaseIterable {
    case fiveMinutes
    case tenMinutes
    case fifteenMinutes
    case twentyFiveMinutes
    case thirtyMinutes
    case fortyFiveMinutes
    case oneHour

    var duration: TimeInterval {
        switch self {
        case .fiveMinutes: return 5 * 60
        case .tenMinutes: return 10 * 60
        case .fifteenMinutes: return 15 * 60
        case .twentyFiveMinutes: return 25 * 60
        case .thirtyMinutes: return 30 * 60
        case .fortyFiveMinutes: return 45 * 60
        case .oneHour: return 60 * 60
        }
    }

    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 min"
        case .tenMinutes: return "10 min"
        case .fifteenMinutes: return "15 min"
        case .twentyFiveMinutes: return "25 min"
        case .thirtyMinutes: return "30 min"
        case .fortyFiveMinutes: return "45 min"
        case .oneHour: return "1 hour"
        }
    }

    /// Recommended age group for this duration
    var recommendedAgeRange: ClosedRange<Int> {
        switch self {
        case .fiveMinutes: return 4...6
        case .tenMinutes: return 5...7
        case .fifteenMinutes: return 6...8
        case .twentyFiveMinutes: return 8...10
        case .thirtyMinutes: return 9...12
        case .fortyFiveMinutes: return 10...14
        case .oneHour: return 12...16
        }
    }
}

/// Break timer configuration
struct BreakConfiguration {
    let breakDuration: TimeInterval
    let autoStartBreak: Bool
    let breakReminder: Bool

    static let `default` = BreakConfiguration(
        breakDuration: 5 * 60,
        autoStartBreak: false,
        breakReminder: true
    )

    static let pomodoro = BreakConfiguration(
        breakDuration: 5 * 60,
        autoStartBreak: true,
        breakReminder: true
    )
}
