//
//  MultiChildTimerManager.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine
import UIKit

/// Manages timers for multiple children concurrently.
/// Each child can have their own independent timer that persists across app sessions.
@MainActor
class MultiChildTimerManager: ObservableObject {

    // MARK: - Published Properties

    /// All active timer states (running or paused)
    @Published private(set) var activeTimers: [UUID: ChildTimerState] = [:]

    /// Timers that have completed and need to show alerts
    @Published var completedTimers: [ChildTimerState] = []

    /// Indicates if timers were restored from a previous session
    @Published private(set) var hasRestoredTimers: Bool = false

    // MARK: - Private Properties

    private static let storageKey = "multiChildTimerStates"
    private var updateTimer: Timer?
    private var persistenceTimer: Timer?  // Timer for aggressive persistence
    private var cancellables = Set<AnyCancellable>()
    private let notificationService: NotificationServiceProtocol
    private let persistenceInterval: TimeInterval = 10.0  // Save state every 10 seconds

    // MARK: - Initialization

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
        loadPersistedStates()
        startUpdateLoop()
        startAggressivePersistence()
        setupNotificationObservers()
    }

    deinit {
        persistenceTimer?.invalidate()
        updateTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Get the timer state for a specific child
    func timerState(for childId: UUID) -> ChildTimerState? {
        activeTimers[childId]
    }

    /// Check if a child has an active timer
    func hasActiveTimer(for childId: UUID) -> Bool {
        activeTimers[childId] != nil
    }

    /// Start a timer for a child
    func startTimer(for child: Child, category: Category, duration: TimeInterval) {
        let state = ChildTimerState.start(child: child, category: category, duration: duration)
        activeTimers[child.id] = state
        persistStates()
        scheduleNotification(for: state)

        // Start Live Activity for lock screen display
        Task {
            await LiveActivityManager.shared.startActivity(for: state)
        }
    }

    /// Pause a child's timer
    func pauseTimer(for childId: UUID) {
        guard let state = activeTimers[childId], !state.isPaused else { return }
        let pausedState = state.paused()
        activeTimers[childId] = pausedState
        persistStates()
        cancelNotification(for: childId)

        // Update Live Activity to show paused state
        Task {
            await LiveActivityManager.shared.updateActivity(for: pausedState)
        }
    }

    /// Resume a child's timer
    func resumeTimer(for childId: UUID) {
        guard let state = activeTimers[childId], state.isPaused else { return }
        let resumedState = state.resumed()
        activeTimers[childId] = resumedState
        persistStates()
        scheduleNotification(for: resumedState)

        // Update Live Activity to show running state
        Task {
            await LiveActivityManager.shared.updateActivity(for: resumedState)
        }
    }

    /// Stop a child's timer (without completing)
    func stopTimer(for childId: UUID) {
        activeTimers.removeValue(forKey: childId)
        persistStates()
        cancelNotification(for: childId)

        // End Live Activity
        Task {
            await LiveActivityManager.shared.endActivity(for: childId)
        }
    }

    /// Add time to a child's timer
    func addTime(for childId: UUID, minutes: Int) {
        guard let state = activeTimers[childId] else { return }
        let additionalTime = TimeInterval(minutes * 60)
        let newState = state.withAddedTime(additionalTime)
        activeTimers[childId] = newState
        persistStates()

        // Reschedule notification if running
        if !newState.isPaused {
            cancelNotification(for: childId)
            scheduleNotification(for: newState)
        }

        // Update Live Activity with new time
        Task {
            await LiveActivityManager.shared.updateActivity(for: newState)
        }
    }

    /// Mark a timer as completed and remove it from active timers
    /// Returns the completed state for activity logging
    func completeTimer(for childId: UUID) -> ChildTimerState? {
        guard let state = activeTimers.removeValue(forKey: childId) else { return nil }
        persistStates()
        cancelNotification(for: childId)

        // End Live Activity
        Task {
            await LiveActivityManager.shared.endActivity(for: childId)
        }

        return state
    }

    /// Dismiss a completed timer alert
    func dismissCompletedTimer(_ state: ChildTimerState) {
        completedTimers.removeAll { $0.childId == state.childId }
    }

    /// Get all children with running timers (for showing indicators)
    func childrenWithActiveTimers() -> [UUID] {
        Array(activeTimers.keys)
    }

    /// Acknowledge that the user has seen the timer restoration
    func acknowledgeTimerRestoration() {
        hasRestoredTimers = false
    }

    /// Public method to persist state when app enters background/inactive
    /// Called from FocusPalApp's scenePhase observer
    func persistStatesOnBackground() async {
        if !activeTimers.isEmpty {
            persistStates()
            print("💾 Saved timer state on scene phase change")
        }
    }

    // MARK: - Private Methods

    private func startUpdateLoop() {
        // Update timer states every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForCompletedTimers()
            }
        }
        RunLoop.current.add(updateTimer!, forMode: .common)
    }

    /// Start aggressive persistence - saves timer state every 10 seconds while timers are running
    /// This ensures timer state is preserved even if the app is force quit
    private func startAggressivePersistence() {
        persistenceTimer = Timer.scheduledTimer(withTimeInterval: persistenceInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.aggressivePersist()
            }
        }
        RunLoop.current.add(persistenceTimer!, forMode: .common)
    }

    /// Aggressively persist running timers to survive force quit
    private func aggressivePersist() {
        // Only persist if there are active running (not paused) timers
        let hasRunningTimers = activeTimers.values.contains { !$0.isPaused }

        if hasRunningTimers {
            persistStates()
            print("📝 Aggressively persisted timer state at \(Date())")
        }
    }

    private func checkForCompletedTimers() {
        var completedChildIds: [UUID] = []

        for (childId, state) in activeTimers {
            if state.isCompleted && !state.isPaused {
                completedChildIds.append(childId)
                completedTimers.append(state)
                // Note: Activity logging is now handled by TimerViewModel after user confirms completion
            }
        }

        // Remove completed timers from active and end Live Activities
        for childId in completedChildIds {
            activeTimers.removeValue(forKey: childId)

            // End Live Activity for completed timer
            Task {
                await LiveActivityManager.shared.endActivity(for: childId)
            }
        }

        if !completedChildIds.isEmpty {
            persistStates()
        }

        // Trigger UI update for remaining timers
        objectWillChange.send()
    }

    private func persistStates() {
        let states = Array(activeTimers.values)
        if let encoded = try? JSONEncoder().encode(states) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }

    private func loadPersistedStates() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let states = try? JSONDecoder().decode([ChildTimerState].self, from: data) else {
            hasRestoredTimers = false
            return
        }

        // Track if we restored any timers
        var restoredCount = 0
        var restoredActiveStates: [ChildTimerState] = []

        // Restore states, checking for completed timers
        for state in states {
            if state.isCompleted && !state.isPaused {
                // Timer completed while app was closed
                completedTimers.append(state)
                restoredCount += 1
            } else {
                activeTimers[state.childId] = state
                restoredActiveStates.append(state)
                restoredCount += 1
            }
        }

        // Set restoration flag if we restored any timers
        hasRestoredTimers = restoredCount > 0

        if hasRestoredTimers {
            print("🔄 Restored \(restoredCount) timer(s) from previous session")

            // Restart Live Activities for restored active timers
            for state in restoredActiveStates {
                Task {
                    await LiveActivityManager.shared.startActivity(for: state)
                }
            }
        }
    }

    private func scheduleNotification(for state: ChildTimerState) {
        guard !state.isPaused else { return }

        let remainingTime = state.remainingTime
        guard remainingTime > 0 else { return }

        // Schedule completion notification
        notificationService.scheduleTimerCompletion(
            in: remainingTime,
            categoryName: "\(state.childName)'s \(state.categoryName)"
        )

        // Schedule warnings
        if remainingTime > 300 {
            notificationService.scheduleFiveMinuteWarning(
                in: remainingTime - 300,
                categoryName: "\(state.childName)'s \(state.categoryName)"
            )
        }

        if remainingTime > 60 {
            notificationService.scheduleOneMinuteWarning(
                in: remainingTime - 60,
                categoryName: "\(state.childName)'s \(state.categoryName)"
            )
        }
    }

    private func cancelNotification(for childId: UUID) {
        // Cancel notifications for this child
        // Note: Current notification service cancels all - may need enhancement
        // For now, we'll reschedule remaining timers after cancel
        notificationService.cancelTimerNotifications()

        // Reschedule notifications for other active timers
        for (id, state) in activeTimers where id != childId && !state.isPaused {
            scheduleNotification(for: state)
        }
    }

    private func setupNotificationObservers() {
        // Check for completed timers when app returns to foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkForCompletedTimers()
            }
        }

        // Save state when app enters background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterBackground()
            }
        }

        // Save state when app will resign active (covers force quit scenarios)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWillResignActive()
            }
        }

        // Save state when app will terminate (if we get this notification)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWillTerminate()
            }
        }
    }

    /// Handle app entering background - save timer state
    private func handleEnterBackground() {
        if !activeTimers.isEmpty {
            persistStates()
            print("💾 Saved timer state on entering background")
        }
    }

    /// Handle app about to become inactive - save timer state
    private func handleWillResignActive() {
        if !activeTimers.isEmpty {
            persistStates()
            print("💾 Saved timer state on will resign active")
        }
    }

    /// Handle app termination - save timer state
    private func handleWillTerminate() {
        if !activeTimers.isEmpty {
            persistStates()
            print("💾 Saved timer state on will terminate")
        }
    }
}
