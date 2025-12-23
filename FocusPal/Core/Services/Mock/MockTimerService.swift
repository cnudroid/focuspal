//
//  MockTimerService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// Mock implementation of TimerService for testing and previews.
class MockTimerService: TimerServiceProtocol {

    // MARK: - Mock Data

    @Published var mockTimerState: TimerState = .idle
    @Published var mockRemainingTime: TimeInterval = 0
    @Published var mockElapsedTime: TimeInterval = 0

    var startTimerCallCount = 0
    var pauseTimerCallCount = 0
    var resumeTimerCallCount = 0
    var stopTimerCallCount = 0
    var addTimeCallCount = 0
    var lastAddedTime: TimeInterval = 0

    // MARK: - Publishers

    var timerStatePublisher: AnyPublisher<TimerState, Never> {
        $mockTimerState.eraseToAnyPublisher()
    }

    var remainingTimePublisher: AnyPublisher<TimeInterval, Never> {
        $mockRemainingTime.eraseToAnyPublisher()
    }

    var elapsedTimePublisher: AnyPublisher<TimeInterval, Never> {
        $mockElapsedTime.eraseToAnyPublisher()
    }

    // MARK: - TimerServiceProtocol

    func startTimer(duration: TimeInterval, mode: TimerMode, category: Category?) {
        startTimerCallCount += 1
        mockTimerState = .running
        mockRemainingTime = duration
    }

    func pauseTimer() {
        pauseTimerCallCount += 1
        mockTimerState = .paused
    }

    func resumeTimer() {
        resumeTimerCallCount += 1
        mockTimerState = .running
    }

    func stopTimer() {
        stopTimerCallCount += 1
        mockTimerState = .idle
        mockRemainingTime = 0
        mockElapsedTime = 0
    }

    func addTime(_ time: TimeInterval) {
        addTimeCallCount += 1
        lastAddedTime = time
        mockRemainingTime += time
    }

    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        // No-op for mock
    }

    // MARK: - Helper Methods

    func simulateTimerComplete() {
        mockTimerState = .completed
        mockRemainingTime = 0
    }

    func reset() {
        mockTimerState = .idle
        mockRemainingTime = 0
        mockElapsedTime = 0
        startTimerCallCount = 0
        pauseTimerCallCount = 0
        resumeTimerCallCount = 0
        stopTimerCallCount = 0
        addTimeCallCount = 0
        lastAddedTime = 0
    }
}
