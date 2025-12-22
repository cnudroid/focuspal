//
//  TimerViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Timer screen.
/// Manages timer state and coordinates with TimerService.
@MainActor
class TimerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var timerState: TimerState = .idle
    @Published var remainingTime: TimeInterval = 0
    @Published var progress: Double = 1.0
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var visualizationMode: TimerVisualizationMode = .circular
    @Published var defaultDuration: TimeInterval = 25 * 60  // 25 minutes

    // MARK: - Dependencies

    private let timerService: TimerServiceProtocol
    private let activityService: ActivityServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var totalDuration: TimeInterval = 0

    // MARK: - Initialization

    init(
        timerService: TimerServiceProtocol? = nil,
        activityService: ActivityServiceProtocol? = nil
    ) {
        self.timerService = timerService ?? MockTimerService()
        self.activityService = activityService ?? MockActivityService()

        setupBindings()
        loadCategories()
    }

    // MARK: - Setup

    private func setupBindings() {
        timerService.timerStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$timerState)

        timerService.remainingTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                self?.remainingTime = remaining
                self?.updateProgress()
            }
            .store(in: &cancellables)
    }

    private func loadCategories() {
        // Load mock categories for now
        categories = [
            Category(name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", childId: UUID()),
            Category(name: "Reading", iconName: "text.book.closed.fill", colorHex: "#7B68EE", childId: UUID()),
            Category(name: "Screen Time", iconName: "tv.fill", colorHex: "#FF6B6B", childId: UUID()),
            Category(name: "Playing", iconName: "gamecontroller.fill", colorHex: "#4ECDC4", childId: UUID())
        ]
        selectedCategory = categories.first
    }

    // MARK: - Timer Controls

    func startTimer() {
        totalDuration = defaultDuration
        remainingTime = defaultDuration
        progress = 1.0

        timerService.startTimer(
            duration: defaultDuration,
            mode: .countdown(duration: defaultDuration),
            category: selectedCategory
        )
    }

    func pauseTimer() {
        timerService.pauseTimer()
    }

    func resumeTimer() {
        timerService.resumeTimer()
    }

    func stopTimer() {
        // Log activity if timer was running
        if timerState == .completed || timerState == .running || timerState == .paused {
            logCompletedActivity()
        }

        timerService.stopTimer()
        progress = 1.0
        remainingTime = defaultDuration
    }

    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        visualizationMode = mode
        timerService.setVisualizationMode(mode)
    }

    // MARK: - Private Methods

    private func updateProgress() {
        guard totalDuration > 0 else { return }
        progress = remainingTime / totalDuration
    }

    private func logCompletedActivity() {
        guard let category = selectedCategory else { return }

        let duration = totalDuration - remainingTime

        Task {
            let mockChild = Child(name: "Test", age: 8)
            _ = try? await activityService.logActivity(
                category: category,
                duration: duration,
                child: mockChild
            )
        }
    }
}
