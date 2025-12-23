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
    @Published var selectedCategory: Category? {
        didSet {
            // Update duration when category changes
            if let category = selectedCategory {
                defaultDuration = category.recommendedDuration
                if timerState == .idle {
                    remainingTime = defaultDuration
                }
            }
        }
    }
    @Published var visualizationMode: TimerVisualizationMode = .circular
    @Published var defaultDuration: TimeInterval = 25 * 60  // 25 minutes
    @Published var audioCalloutsEnabled: Bool = true
    @Published var childName: String = "Buddy"

    // Time tracking for actual duration
    @Published var actualStartTime: Date?
    @Published var actualDuration: TimeInterval = 0
    @Published var timeAdded: TimeInterval = 0  // Extra time added during session

    // MARK: - Dependencies

    private let timerService: TimerServiceProtocol
    private let activityService: ActivityServiceProtocol
    private let audioService = TimerAudioService()
    private var cancellables = Set<AnyCancellable>()
    private var totalDuration: TimeInterval = 0
    private let childId: UUID

    // MARK: - Initialization

    init(
        timerService: TimerServiceProtocol? = nil,
        activityService: ActivityServiceProtocol? = nil,
        childId: UUID = UUID()
    ) {
        self.timerService = timerService ?? MockTimerService()
        self.activityService = activityService ?? MockActivityService()
        self.childId = childId

        setupBindings()
        loadCategories()
        loadChildName()
    }

    private func loadChildName() {
        // Load child name from UserDefaults (set during onboarding)
        if let name = UserDefaults.standard.string(forKey: "childName_\(childId.uuidString)") {
            childName = name
        } else if let name = UserDefaults.standard.string(forKey: "childName") {
            childName = name
        }
    }

    func setChildName(_ name: String) {
        childName = name
        UserDefaults.standard.set(name, forKey: "childName")
        UserDefaults.standard.set(name, forKey: "childName_\(childId.uuidString)")
    }

    // MARK: - Setup

    private func setupBindings() {
        timerService.timerStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$timerState)

        timerService.remainingTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                guard let self = self else { return }
                self.remainingTime = remaining
                self.updateProgress()

                // Check for audio callouts
                if self.timerState == .running {
                    self.audioService.checkForAnnouncements(
                        remainingTime: remaining,
                        totalDuration: self.totalDuration
                    )
                }
            }
            .store(in: &cancellables)

        // Sync audio enabled state
        $audioCalloutsEnabled
            .sink { [weak self] enabled in
                self?.audioService.isEnabled = enabled
            }
            .store(in: &cancellables)
    }

    private func loadCategories() {
        // Try to load saved categories from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savedCategories_\(childId.uuidString)"),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory(childId: childId) }
        } else {
            // Use default categories
            categories = Category.defaultCategories(for: childId)
        }

        // Select first category and set its duration
        if let firstCategory = categories.first {
            selectedCategory = firstCategory
            defaultDuration = firstCategory.recommendedDuration
            remainingTime = defaultDuration
        }
    }

    /// Reload categories (call when returning from settings)
    func reloadCategories() {
        let currentSelectedId = selectedCategory?.id
        loadCategories()

        // Try to keep the same category selected
        if let id = currentSelectedId,
           let category = categories.first(where: { $0.id == id }) {
            selectedCategory = category
        }
    }

    // MARK: - Timer Controls

    func startTimer() {
        // Use the selected category's duration
        let duration = selectedCategory?.recommendedDuration ?? defaultDuration
        totalDuration = duration
        remainingTime = duration
        progress = 1.0
        timeAdded = 0
        actualStartTime = Date()
        actualDuration = 0

        // Reset audio announcements
        audioService.reset()

        timerService.startTimer(
            duration: duration,
            mode: .countdown(duration: duration),
            category: selectedCategory
        )
    }

    /// Complete task early (before timer ends)
    func completeEarly() {
        guard timerState == .running || timerState == .paused else { return }

        // Calculate actual duration
        if let startTime = actualStartTime {
            actualDuration = Date().timeIntervalSince(startTime)
        }

        // Log the activity with actual duration
        logCompletedActivity(wasCompletedEarly: true)

        // Stop the timer
        timerService.stopTimer()
        audioService.reset()
        timerState = .completed

        // Reset for next session
        resetForNextSession()
    }

    /// Add extra time to the current timer
    func addTime(minutes: Int) {
        guard timerState == .running || timerState == .paused else { return }

        let additionalTime = TimeInterval(minutes * 60)
        timeAdded += additionalTime
        totalDuration += additionalTime
        remainingTime += additionalTime

        // Update the timer service
        timerService.addTime(additionalTime)
    }

    private func resetForNextSession() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.progress = 1.0
            self.remainingTime = self.selectedCategory?.recommendedDuration ?? self.defaultDuration
            self.timerState = .idle
            self.actualStartTime = nil
            self.actualDuration = 0
            self.timeAdded = 0
        }
    }

    func pauseTimer() {
        timerService.pauseTimer()
    }

    func resumeTimer() {
        timerService.resumeTimer()
    }

    func stopTimer() {
        // Calculate actual duration
        if let startTime = actualStartTime {
            actualDuration = Date().timeIntervalSince(startTime)
        }

        // Log activity if timer was running
        if timerState == .completed || timerState == .running || timerState == .paused {
            logCompletedActivity(wasCompletedEarly: false)
        }

        timerService.stopTimer()
        audioService.reset()
        progress = 1.0
        remainingTime = selectedCategory?.recommendedDuration ?? defaultDuration
        actualStartTime = nil
        actualDuration = 0
        timeAdded = 0
    }

    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        visualizationMode = mode
        timerService.setVisualizationMode(mode)
    }

    func toggleAudioCallouts() {
        audioCalloutsEnabled.toggle()
    }

    // MARK: - Private Methods

    private func updateProgress() {
        guard totalDuration > 0 else { return }
        progress = remainingTime / totalDuration
    }

    private func logCompletedActivity(wasCompletedEarly: Bool) {
        guard let category = selectedCategory else { return }

        // Use actual duration if available, otherwise calculate from timer
        let duration = actualDuration > 0 ? actualDuration : (totalDuration - remainingTime)

        Task {
            let child = Child(name: childName, age: 8)
            _ = try? await activityService.logActivity(
                category: category,
                duration: duration,
                child: child
            )
        }

        // Log for debugging
        let plannedMinutes = Int(totalDuration / 60)
        let actualMinutes = Int(duration / 60)
        let actualSeconds = Int(duration) % 60
        print("📊 Activity logged: \(category.name)")
        print("   Planned: \(plannedMinutes) min")
        print("   Actual: \(actualMinutes)m \(actualSeconds)s")
        print("   Completed early: \(wasCompletedEarly)")
        if timeAdded > 0 {
            print("   Extra time added: \(Int(timeAdded / 60)) min")
        }
    }

    /// Formatted string for actual elapsed time
    var elapsedTimeFormatted: String {
        guard let startTime = actualStartTime else { return "0:00" }
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted string for time added
    var timeAddedFormatted: String {
        guard timeAdded > 0 else { return "" }
        let minutes = Int(timeAdded / 60)
        return "+\(minutes) min"
    }
}

// MARK: - CategoryData for UserDefaults persistence

private struct CategoryData: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let isSystem: Bool
    let recommendedDuration: TimeInterval

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconName = category.iconName
        self.colorHex = category.colorHex
        self.isActive = category.isActive
        self.sortOrder = category.sortOrder
        self.isSystem = category.isSystem
        self.recommendedDuration = category.recommendedDuration
    }

    func toCategory(childId: UUID) -> Category {
        Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: sortOrder,
            isSystem: isSystem,
            childId: childId,
            recommendedDuration: recommendedDuration
        )
    }
}
