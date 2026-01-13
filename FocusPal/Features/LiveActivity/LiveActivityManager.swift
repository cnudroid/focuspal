//
//  LiveActivityManager.swift
//  FocusPal
//
//  Created by FocusPal Team
//
//  Manages Live Activity lifecycle for timer sessions.
//  Handles starting, updating, and ending Live Activities for lock screen
//  and Dynamic Island display.
//

import ActivityKit
import Foundation

/// Manages Live Activity lifecycle for timer sessions
@MainActor
class LiveActivityManager: ObservableObject {

    // MARK: - Singleton

    static let shared = LiveActivityManager()

    // MARK: - Properties

    /// Active Live Activities keyed by child ID (type-erased for iOS version compatibility)
    private var activeActivities: [UUID: Any] = [:]

    // MARK: - Initialization

    private init() {
        // Clean up any stale activities on init
        if #available(iOS 16.2, *) {
            Task {
                await cleanupStaleActivities()
            }
        }
    }

    // MARK: - Public Properties

    /// Check if Live Activities are supported and enabled
    var isSupported: Bool {
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }

    /// Check if Live Activities feature is available on this iOS version
    var isAvailable: Bool {
        if #available(iOS 16.2, *) {
            return true
        }
        return false
    }

    // MARK: - Public Methods

    /// Start a Live Activity for a timer
    /// - Parameter state: The timer state to display
    func startActivity(for state: ChildTimerState) async {
        guard #available(iOS 16.2, *) else {
            print("📱 Live Activities not available on this iOS version")
            return
        }

        guard isSupported else {
            print("📱 Live Activities not supported or disabled on this device")
            return
        }

        // Don't start activity for completed or paused timers
        guard !state.isCompleted else {
            print("📱 Timer already completed, not starting Live Activity")
            return
        }

        // End any existing activity for this child first
        await endActivity(for: state.childId)

        // Create attributes from timer state
        let attributes = FocusPalTimerAttributes(from: state)

        // Create initial content state
        let contentState = FocusPalTimerAttributes.ContentState(from: state)

        // Debug: Print authorization status
        let authInfo = ActivityAuthorizationInfo()
        print("📱 ActivityKit Debug:")
        print("   areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        print("   frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")

        // Debug: Print attributes being sent
        print("📱 Attributes: childName=\(attributes.childName), category=\(attributes.categoryName)")
        print("📱 ContentState: remaining=\(contentState.remainingTime), paused=\(contentState.isPaused)")

        do {
            let activity = try ActivityKit.Activity<FocusPalTimerAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: nil),
                pushType: nil  // Local updates only, no push notifications
            )

            activeActivities[state.childId] = activity
            print("📱 Started Live Activity for \(state.childName)'s \(state.categoryName)")
            print("   Activity ID: \(activity.id)")
            print("   Activity State: \(activity.activityState)")

            // List all current activities
            let allActivities = ActivityKit.Activity<FocusPalTimerAttributes>.activities
            print("📱 Total active Live Activities: \(allActivities.count)")
            for act in allActivities {
                print("   - \(act.id): \(act.activityState)")
            }
        } catch {
            print("📱 Failed to start Live Activity: \(error.localizedDescription)")
            print("📱 Error details: \(error)")
        }
    }

    /// Update an existing Live Activity with new timer state
    /// - Parameter state: The updated timer state
    func updateActivity(for state: ChildTimerState) async {
        guard #available(iOS 16.2, *) else { return }

        guard let activity = activeActivities[state.childId] as? ActivityKit.Activity<FocusPalTimerAttributes> else {
            // No active activity - start one if timer is running and not completed
            if !state.isCompleted {
                await startActivity(for: state)
            }
            return
        }

        // If timer completed, end the activity
        if state.isCompleted {
            await endActivity(for: state.childId)
            return
        }

        let contentState = FocusPalTimerAttributes.ContentState(from: state)

        await activity.update(
            ActivityContent(state: contentState, staleDate: nil)
        )
        print("📱 Updated Live Activity for \(state.childName) - \(state.isPaused ? "Paused" : "Running")")
    }

    /// End a Live Activity for a specific child
    /// - Parameter childId: The child ID whose activity should end
    func endActivity(for childId: UUID) async {
        guard #available(iOS 16.2, *) else { return }

        guard let activity = activeActivities[childId] as? ActivityKit.Activity<FocusPalTimerAttributes> else { return }

        // Create final state showing completed
        let finalState = FocusPalTimerAttributes.ContentState(
            remainingTime: 0,
            isPaused: false,
            timerEndDate: Date(),
            totalDuration: activity.attributes.totalDuration
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: ActivityUIDismissalPolicy.immediate
        )

        activeActivities.removeValue(forKey: childId)
        print("📱 Ended Live Activity for child: \(childId)")
    }

    /// End all active Live Activities
    func endAllActivities() async {
        guard #available(iOS 16.2, *) else { return }

        for childId in activeActivities.keys {
            await endActivity(for: childId)
        }
        print("📱 Ended all Live Activities")
    }

    /// Check if a Live Activity is active for a child
    /// - Parameter childId: The child ID to check
    /// - Returns: true if an activity is active
    func hasActiveActivity(for childId: UUID) -> Bool {
        return activeActivities[childId] != nil
    }

    /// Get count of active Live Activities
    var activeActivityCount: Int {
        return activeActivities.count
    }

    // MARK: - Private Methods

    /// Clean up any stale activities from previous app sessions
    @available(iOS 16.2, *)
    private func cleanupStaleActivities() async {
        // End all ongoing activities from previous sessions
        for activity in ActivityKit.Activity<FocusPalTimerAttributes>.activities {
            await activity.end(
                ActivityContent(
                    state: FocusPalTimerAttributes.ContentState(
                        remainingTime: 0,
                        isPaused: false,
                        timerEndDate: Date(),
                        totalDuration: activity.attributes.totalDuration
                    ),
                    staleDate: nil
                ),
                dismissalPolicy: ActivityUIDismissalPolicy.immediate
            )
        }
        print("📱 Cleaned up stale Live Activities")
    }
}

// MARK: - Preview Support

#if DEBUG
extension LiveActivityManager {
    /// Request Live Activity permission (for testing)
    func requestPermission() async -> Bool {
        guard isAvailable else { return false }

        // Check current authorization status
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
}
#endif
