//
//  TimerServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Protocol defining the timer service interface.
/// Manages countdown timers for timed activities.
protocol TimerServiceProtocol {
    /// Publisher for the current timer state
    var timerStatePublisher: AnyPublisher<TimerState, Never> { get }

    /// Publisher for remaining time in seconds
    var remainingTimePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// Publisher for elapsed time in seconds
    var elapsedTimePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// Start a new timer session
    /// - Parameters:
    ///   - duration: Timer duration in seconds
    ///   - mode: The timer mode (countdown or stopwatch)
    ///   - category: Optional category for the activity
    func startTimer(duration: TimeInterval, mode: TimerMode, category: Category?)

    /// Pause the current timer
    func pauseTimer()

    /// Resume a paused timer
    func resumeTimer()

    /// Stop and reset the timer
    func stopTimer()

    /// Add additional time to the current timer
    /// - Parameter time: Additional time in seconds
    func addTime(_ time: TimeInterval)

    /// Set the visualization mode for the timer display
    func setVisualizationMode(_ mode: TimerVisualizationMode)
}

/// Timer operational states
enum TimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}

/// Timer counting modes
enum TimerMode: Equatable {
    case countdown(duration: TimeInterval)
    case stopwatch
}

/// Timer visual display modes
enum TimerVisualizationMode: String, CaseIterable {
    case circular
    case bar
    case analog
}
