//
//  TimerService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine
import UIKit

/// Concrete implementation of the timer service.
/// Manages countdown and stopwatch timers with background support.
@MainActor
class TimerService: TimerServiceProtocol {

    // MARK: - Published Properties

    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var elapsedTime: TimeInterval = 0

    // MARK: - Publishers

    var timerStatePublisher: AnyPublisher<TimerState, Never> {
        $timerState.eraseToAnyPublisher()
    }

    var remainingTimePublisher: AnyPublisher<TimeInterval, Never> {
        $remainingTime.eraseToAnyPublisher()
    }

    var elapsedTimePublisher: AnyPublisher<TimeInterval, Never> {
        $elapsedTime.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var currentMode: TimerMode = .stopwatch
    private var currentCategory: Category?
    private var visualizationMode: TimerVisualizationMode = .circular
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private let notificationService: NotificationServiceProtocol

    // MARK: - Initialization

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
        setupBackgroundHandling()
    }

    // MARK: - Timer Control

    func startTimer(duration: TimeInterval, mode: TimerMode, category: Category?) {
        currentMode = mode
        currentCategory = category
        totalDuration = duration
        startTime = Date()
        pausedTime = 0

        switch mode {
        case .countdown(let duration):
            remainingTime = duration
            scheduleTimerNotification(duration: duration)
        case .stopwatch:
            elapsedTime = 0
        }

        timerState = .running
        startTimerLoop()
        beginBackgroundTask()
    }

    func pauseTimer() {
        guard timerState == .running else { return }

        timer?.invalidate()
        timer = nil

        if let start = startTime {
            pausedTime += Date().timeIntervalSince(start)
        }

        timerState = .paused
        notificationService.cancelNotifications(withIdentifier: "timer_completion")
    }

    func resumeTimer() {
        guard timerState == .paused else { return }

        startTime = Date()
        timerState = .running
        startTimerLoop()

        if case .countdown = currentMode {
            scheduleTimerNotification(duration: remainingTime)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        remainingTime = 0
        elapsedTime = 0
        pausedTime = 0
        startTime = nil

        notificationService.cancelNotifications(withIdentifier: "timer_completion")
        endBackgroundTask()
    }

    func addTime(_ time: TimeInterval) {
        guard timerState == .running || timerState == .paused else { return }

        // Update total duration and remaining time
        totalDuration += time
        remainingTime += time

        // Update the countdown mode with new duration
        if case .countdown = currentMode {
            currentMode = .countdown(duration: totalDuration)
        }

        // Reschedule notification if running
        if timerState == .running {
            notificationService.cancelNotifications(withIdentifier: "timer_completion")
            scheduleTimerNotification(duration: remainingTime)
        }
    }

    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        visualizationMode = mode
    }

    // MARK: - Private Methods

    private func startTimerLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func updateTimer() {
        guard let start = startTime else { return }

        let currentElapsed = pausedTime + Date().timeIntervalSince(start)

        switch currentMode {
        case .countdown(let duration):
            remainingTime = max(0, duration - currentElapsed)
            if remainingTime <= 0 {
                timerCompleted()
            }
        case .stopwatch:
            elapsedTime = currentElapsed
        }
    }

    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        timerState = .completed
        endBackgroundTask()
    }

    private func scheduleTimerNotification(duration: TimeInterval) {
        let categoryName = currentCategory?.name ?? "Activity"
        notificationService.scheduleTimerCompletion(in: duration, categoryName: categoryName)
    }

    private func setupBackgroundHandling() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEnterBackground()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEnterForeground()
        }
    }

    private func handleEnterBackground() {
        // Timer continues via notification scheduling
    }

    private func handleEnterForeground() {
        // Recalculate timer state based on elapsed time
        if timerState == .running {
            updateTimer()
        }
    }

    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
