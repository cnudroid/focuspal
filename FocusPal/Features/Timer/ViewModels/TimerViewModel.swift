//
//  TimerViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for the Timer screen.
/// Manages timer state and coordinates with MultiChildTimerManager for per-child timers.
@MainActor
class TimerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var timerState: TimerState
    @Published var remainingTime: TimeInterval
    @Published var progress: Double
    @Published var isRestoring: Bool
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category? {
        didSet {
            // Update duration when category changes (only when idle)
            if let category = selectedCategory, timerState == .idle {
                defaultDuration = category.recommendedDuration
                remainingTime = defaultDuration
            }
        }
    }
    @Published var visualizationMode: TimerVisualizationMode = .circular
    @Published var defaultDuration: TimeInterval = 25 * 60  // 25 minutes
    @Published var audioCalloutsEnabled: Bool = true
    @Published var childName: String = "Buddy"
    @Published var timeAdded: TimeInterval = 0
    @Published var pendingCompletionState: ChildTimerState?  // For completion prompt

    // MARK: - Dependencies

    private let timerManager: MultiChildTimerManager
    private let activityService: ActivityServiceProtocol
    private let audioService = TimerAudioService()
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let currentChild: Child

    // MARK: - Initialization

    init(
        timerManager: MultiChildTimerManager? = nil,
        activityService: ActivityServiceProtocol? = nil,
        currentChild: Child? = nil
    ) {
        // Use real services by default
        let activityRepo = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        let notificationService = NotificationService()

        let manager = timerManager ?? MultiChildTimerManager(notificationService: notificationService)
        let child = currentChild ?? Child(name: "Buddy", age: 8)

        self.timerManager = manager
        self.activityService = activityService ?? ActivityService(repository: activityRepo)
        self.currentChild = child

        // Check for existing timer state BEFORE setting initial values
        // This prevents animation by setting the correct initial progress from the start
        if let existingState = manager.timerState(for: child.id) {
            // Initialize with restored values - no state change will occur
            self._timerState = Published(initialValue: existingState.isPaused ? .paused : (existingState.isCompleted ? .completed : .running))
            self._progress = Published(initialValue: existingState.progress)
            self._remainingTime = Published(initialValue: existingState.remainingTime)
            self._isRestoring = Published(initialValue: false)
        } else {
            // No active timer - set idle state from the start
            self._timerState = Published(initialValue: .idle)
            self._progress = Published(initialValue: 1.0)
            self._remainingTime = Published(initialValue: 0)
            self._isRestoring = Published(initialValue: false)
        }

        self.childName = child.name

        loadCategories()

        // If there was an existing timer, restore category selection
        if let existingState = manager.timerState(for: child.id) {
            if let category = categories.first(where: { $0.id == existingState.categoryId }) {
                // Use _selectedCategory to avoid triggering didSet
                self._selectedCategory = Published(initialValue: category)
            }
            timeAdded = max(0, existingState.totalDuration - (selectedCategory?.recommendedDuration ?? existingState.totalDuration))
        }

        setupBindings()
        startUpdateLoop()
    }

    deinit {
        updateTimer?.invalidate()
    }

    func setChildName(_ name: String) {
        childName = name
        UserDefaults.standard.set(name, forKey: "childName_\(currentChild.id.uuidString)")
    }

    // MARK: - Setup

    private func setupBindings() {
        // Sync audio enabled state
        $audioCalloutsEnabled
            .sink { [weak self] enabled in
                self?.audioService.isEnabled = enabled
            }
            .store(in: &cancellables)

        // Listen for timer manager changes
        timerManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncWithManager()
            }
            .store(in: &cancellables)
    }

    private func startUpdateLoop() {
        // Update UI every 0.1 seconds when timer is running
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateFromManager()
            }
        }
        RunLoop.current.add(updateTimer!, forMode: .common)
    }

    private func syncWithManager() {
        if let state = timerManager.timerState(for: currentChild.id) {
            if state.isPaused {
                timerState = .paused
            } else if state.isCompleted {
                timerState = .completed
            } else {
                timerState = .running
            }
        }
    }

    private func updateFromManager() {
        guard let state = timerManager.timerState(for: currentChild.id) else {
            // No active timer for this child
            if timerState != .idle && timerState != .completed {
                timerState = .idle
                progress = 1.0
                remainingTime = selectedCategory?.recommendedDuration ?? defaultDuration
            }
            return
        }

        // Update from manager state
        remainingTime = state.remainingTime
        progress = state.progress

        if state.isPaused {
            timerState = .paused
        } else if state.isCompleted {
            // Timer completed
            handleTimerCompletion(state: state)
        } else {
            timerState = .running

            // Check for audio callouts
            audioService.checkForAnnouncements(
                remainingTime: remainingTime,
                totalDuration: state.totalDuration
            )
        }
    }

    private func handleTimerCompletion(state: ChildTimerState) {
        timerState = .completed
        audioService.reset()

        // Remove from manager
        _ = timerManager.completeTimer(for: currentChild.id)

        // Show completion prompt instead of auto-logging
        pendingCompletionState = state
    }

    /// Called when user confirms they completed the activity
    func confirmCompletion() {
        guard let state = pendingCompletionState else { return }
        logCompletedActivity(state: state, isComplete: true)
        pendingCompletionState = nil
        resetForNextSession()
    }

    /// Called when user says they didn't finish
    func markIncomplete() {
        guard let state = pendingCompletionState else { return }
        logCompletedActivity(state: state, isComplete: false)
        pendingCompletionState = nil
        resetForNextSession()
    }

    private static let globalCategoryKey = "globalCategories"

    private func loadCategories() {
        // Try to load categories from shared storage first
        if let data = UserDefaults.standard.data(forKey: Self.globalCategoryKey),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory(childId: currentChild.id) }.filter { $0.isActive }
        } else {
            categories = Category.defaultCategories(for: currentChild.id)
        }

        // Select first category and set its duration (only if no active timer)
        if timerManager.timerState(for: currentChild.id) == nil {
            if let firstCategory = categories.first {
                selectedCategory = firstCategory
                defaultDuration = firstCategory.recommendedDuration
                remainingTime = defaultDuration
            }
        }
    }

    /// Reload categories (call when returning from settings)
    func reloadCategories() {
        let currentSelectedId = selectedCategory?.id

        // Reload from shared storage
        if let data = UserDefaults.standard.data(forKey: Self.globalCategoryKey),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory(childId: currentChild.id) }.filter { $0.isActive }
        } else {
            categories = Category.defaultCategories(for: currentChild.id)
        }

        // Try to keep the same category selected
        if let id = currentSelectedId,
           let category = categories.first(where: { $0.id == id }) {
            selectedCategory = category
        } else if timerState == .idle, let firstCategory = categories.first {
            selectedCategory = firstCategory
            defaultDuration = firstCategory.recommendedDuration
            remainingTime = defaultDuration
        }
    }

    // MARK: - Timer Controls

    func startTimer() {
        guard let category = selectedCategory else { return }

        let duration = category.recommendedDuration
        timeAdded = 0

        // Reset audio announcements
        audioService.reset()

        // Start timer through manager
        timerManager.startTimer(for: currentChild, category: category, duration: duration)
        timerState = .running
        remainingTime = duration
        progress = 1.0
    }

    func pauseTimer() {
        timerManager.pauseTimer(for: currentChild.id)
        timerState = .paused
    }

    func resumeTimer() {
        timerManager.resumeTimer(for: currentChild.id)
        timerState = .running
    }

    func stopTimer() {
        // Stopping cancels the timer - don't log activity
        timerManager.stopTimer(for: currentChild.id)
        timerState = .idle
        audioService.reset()
        progress = 1.0
        remainingTime = selectedCategory?.recommendedDuration ?? defaultDuration
        timeAdded = 0
        pendingCompletionState = nil
    }

    /// Complete task early (before timer ends)
    func completeEarly() {
        guard timerState == .running || timerState == .paused else { return }

        // Get current state for logging - marked as complete since user said they finished
        if let state = timerManager.timerState(for: currentChild.id) {
            logCompletedActivity(state: state, isComplete: true)
        }

        timerManager.stopTimer(for: currentChild.id)
        audioService.reset()
        timerState = .completed

        resetForNextSession()
    }

    /// Add extra time to the current timer
    func addTime(minutes: Int) {
        guard timerState == .running || timerState == .paused else { return }

        let additionalTime = TimeInterval(minutes * 60)
        timeAdded += additionalTime

        timerManager.addTime(for: currentChild.id, minutes: minutes)
    }

    private func resetForNextSession() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.progress = 1.0
            self.remainingTime = self.selectedCategory?.recommendedDuration ?? self.defaultDuration
            self.timerState = .idle
            self.timeAdded = 0
        }
    }

    func setVisualizationMode(_ mode: TimerVisualizationMode) {
        visualizationMode = mode
    }

    func toggleAudioCallouts() {
        audioCalloutsEnabled.toggle()
    }

    // MARK: - Private Methods

    private func logCompletedActivity(state: ChildTimerState, isComplete: Bool) {
        let duration = state.elapsedTime
        let category = categories.first { $0.id == state.categoryId }

        guard let category = category else {
            print("❌ Category not found, cannot log activity")
            return
        }

        let actualMinutes = Int(duration / 60)
        let actualSeconds = Int(duration) % 60
        print("📊 LOGGING Activity for \(currentChild.name): \(category.name)")
        print("   Child ID: \(currentChild.id)")
        print("   Category ID: \(category.id)")
        print("   Duration: \(actualMinutes)m \(actualSeconds)s")
        print("   Completed: \(isComplete)")

        Task {
            do {
                let activity = try await activityService.logActivity(
                    category: category,
                    duration: duration,
                    child: currentChild,
                    isComplete: isComplete
                )
                print("✅ Activity logged successfully: \(activity.id)")
            } catch {
                print("❌ Failed to log activity: \(error)")
            }
        }
    }

    /// Formatted string for actual elapsed time
    var elapsedTimeFormatted: String {
        guard let state = timerManager.timerState(for: currentChild.id) else { return "0:00" }
        let elapsed = state.elapsedTime
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
