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

    // MARK: - Private Properties

    private static let storageKey = "multiChildTimerStates"
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let notificationService: NotificationServiceProtocol
    private let activityService: ActivityServiceProtocol

    // MARK: - Initialization

    init(notificationService: NotificationServiceProtocol, activityService: ActivityServiceProtocol? = nil) {
        self.notificationService = notificationService
        // Create activity service for logging completed timers
        let activityRepo = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        self.activityService = activityService ?? ActivityService(repository: activityRepo)
        loadPersistedStates()
        startUpdateLoop()
        setupNotificationObservers()
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
    }

    /// Pause a child's timer
    func pauseTimer(for childId: UUID) {
        guard let state = activeTimers[childId], !state.isPaused else { return }
        activeTimers[childId] = state.paused()
        persistStates()
        cancelNotification(for: childId)
    }

    /// Resume a child's timer
    func resumeTimer(for childId: UUID) {
        guard let state = activeTimers[childId], state.isPaused else { return }
        let resumedState = state.resumed()
        activeTimers[childId] = resumedState
        persistStates()
        scheduleNotification(for: resumedState)
    }

    /// Stop a child's timer (without completing)
    func stopTimer(for childId: UUID) {
        activeTimers.removeValue(forKey: childId)
        persistStates()
        cancelNotification(for: childId)
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
    }

    /// Mark a timer as completed and remove it from active timers
    /// Returns the completed state for activity logging
    func completeTimer(for childId: UUID) -> ChildTimerState? {
        guard let state = activeTimers.removeValue(forKey: childId) else { return nil }
        persistStates()
        cancelNotification(for: childId)
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

    private func checkForCompletedTimers() {
        var completedChildIds: [UUID] = []

        for (childId, state) in activeTimers {
            if state.isCompleted && !state.isPaused {
                completedChildIds.append(childId)
                completedTimers.append(state)
                // Log the completed activity
                logCompletedActivity(state: state)
            }
        }

        // Remove completed timers from active
        for childId in completedChildIds {
            activeTimers.removeValue(forKey: childId)
        }

        if !completedChildIds.isEmpty {
            persistStates()
        }

        // Trigger UI update for remaining timers
        objectWillChange.send()
    }

    /// Log activity when a timer completes
    private func logCompletedActivity(state: ChildTimerState) {
        let duration = state.elapsedTime

        // Create a child object from the state
        let child = Child(
            id: state.childId,
            name: state.childName,
            age: 8,  // Default age, not critical for logging
            avatarId: "",
            themeColor: "blue"
        )

        // Create a category from the state
        let category = Category(
            id: state.categoryId,
            name: state.categoryName,
            iconName: state.categoryIconName,
            colorHex: state.categoryColorHex,
            childId: state.childId
        )

        let actualMinutes = Int(duration / 60)
        let actualSeconds = Int(duration) % 60
        print("📊 LOGGING Completed Activity for \(state.childName): \(state.categoryName)")
        print("   Child ID: \(state.childId)")
        print("   Duration: \(actualMinutes)m \(actualSeconds)s")

        Task {
            do {
                let activity = try await activityService.logActivity(
                    category: category,
                    duration: duration,
                    child: child
                )
                print("✅ Activity logged successfully: \(activity.id)")
            } catch {
                print("❌ Failed to log activity: \(error)")
            }
        }
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
            return
        }

        // Restore states, checking for completed timers
        for state in states {
            if state.isCompleted && !state.isPaused {
                // Timer completed while app was closed
                completedTimers.append(state)
            } else {
                activeTimers[state.childId] = state
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
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkForCompletedTimers()
            }
        }
    }
}
