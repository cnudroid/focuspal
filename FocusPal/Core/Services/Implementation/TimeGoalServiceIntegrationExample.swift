//
//  TimeGoalServiceIntegrationExample.swift
//  FocusPal
//
//  Created by FocusPal Team
//
//  EXAMPLE ONLY - This file shows how to integrate TimeGoalService
//  into ViewModels and other parts of the app.
//

import Foundation

// MARK: - Example 1: Integration with TimerViewModel

/*
class TimerViewModel: ObservableObject {
    private let timeGoalService: TimeGoalServiceProtocol
    private let activityService: ActivityServiceProtocol
    @Published var currentGoalStatus: TimeGoalStatus = .normal
    @Published var goalProgress: Double = 0.0

    init(
        timeGoalService: TimeGoalServiceProtocol,
        activityService: ActivityServiceProtocol
    ) {
        self.timeGoalService = timeGoalService
        self.activityService = activityService
    }

    // Call this when timer completes to check goal status
    func onTimerComplete(category: Category, child: Child, goal: TimeGoal?) async {
        guard let goal = goal, goal.isActive else { return }

        do {
            // Track time and send notifications if needed
            try await timeGoalService.trackTimeAndNotify(
                categoryId: category.id,
                childId: child.id,
                category: category,
                goal: goal
            )

            // Update UI with current status
            await updateGoalStatus(goal: goal)
        } catch {
            print("Error tracking time goal: \(error)")
        }
    }

    // Update UI with current goal status
    @MainActor
    private func updateGoalStatus(goal: TimeGoal) async {
        do {
            currentGoalStatus = try await timeGoalService.checkGoalStatus(goal: goal)
            goalProgress = try await timeGoalService.calculateProgress(goal: goal)
        } catch {
            print("Error updating goal status: \(error)")
        }
    }
}
*/

// MARK: - Example 2: Integration with TimeGoalsViewModel

/*
class TimeGoalsViewModel: ObservableObject {
    private let timeGoalService: TimeGoalServiceProtocol
    @Published var goals: [TimeGoal] = []
    @Published var goalStatuses: [UUID: TimeGoalStatus] = [:]
    @Published var goalProgress: [UUID: Double] = [:]

    init(timeGoalService: TimeGoalServiceProtocol) {
        self.timeGoalService = timeGoalService
    }

    // Refresh all goal statuses
    func refreshGoalStatuses() async {
        for goal in goals {
            guard goal.isActive else { continue }

            do {
                let status = try await timeGoalService.checkGoalStatus(goal: goal)
                let progress = try await timeGoalService.calculateProgress(goal: goal)

                await MainActor.run {
                    goalStatuses[goal.id] = status
                    goalProgress[goal.id] = progress
                }
            } catch {
                print("Error checking goal status for \(goal.id): \(error)")
            }
        }
    }
}
*/

// MARK: - Example 3: Integration with App Lifecycle

/*
@main
struct FocusPalApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    let timeGoalService: TimeGoalServiceProtocol
    let activityService: ActivityServiceProtocol
    let notificationService: NotificationServiceProtocol

    init() {
        // Initialize services
        let activityRepository = CoreDataActivityRepository(context: PersistenceController.shared.container.viewContext)
        self.activityService = ActivityService(repository: activityRepository)
        self.notificationService = NotificationService()

        // Initialize time goal service with daily reset
        self.timeGoalService = TimeGoalService(
            activityService: activityService,
            notificationService: notificationService
        )

        // The service automatically schedules midnight reset
        // No additional setup needed!
    }
}
*/

// MARK: - Example 4: SwiftUI View with Visual Indicators

/*
struct CategoryCardWithGoalStatus: View {
    let category: Category
    let goal: TimeGoal?
    let timeGoalService: TimeGoalServiceProtocol

    @State private var goalStatus: TimeGoalStatus = .normal
    @State private var progress: Double = 0.0
    @State private var timeUsed: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.headline)

                Spacer()

                // Goal status indicator
                if let goal = goal, goal.isActive {
                    goalStatusBadge
                }
            }

            // Progress bar
            if let goal = goal, goal.isActive {
                ProgressView(value: progress / 100.0)
                    .tint(progressColor)

                Text("\(timeUsed) / \(goal.recommendedMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .task {
            await updateGoalStatus()
        }
    }

    @ViewBuilder
    private var goalStatusBadge: some View {
        switch goalStatus {
        case .normal:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        case .exceeded:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }

    private var progressColor: Color {
        switch goalStatus {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .exceeded:
            return .red
        }
    }

    private func updateGoalStatus() async {
        guard let goal = goal else { return }

        do {
            let status = try await timeGoalService.checkGoalStatus(goal: goal)
            let progressValue = try await timeGoalService.calculateProgress(goal: goal)
            let used = try await timeGoalService.getTimeUsedToday(
                categoryId: category.id,
                childId: goal.childId
            )

            await MainActor.run {
                self.goalStatus = status
                self.progress = progressValue
                self.timeUsed = used
            }
        } catch {
            print("Error updating goal status: \(error)")
        }
    }
}
*/

// MARK: - Example 5: Manual Daily Reset (if needed)

/*
// In case you need to manually trigger reset (e.g., for testing)
class TimeGoalManager {
    private let timeGoalService: TimeGoalServiceProtocol

    init(timeGoalService: TimeGoalServiceProtocol) {
        self.timeGoalService = timeGoalService
    }

    // Manually reset daily tracking (for testing or manual intervention)
    func resetDailyTracking() {
        timeGoalService.resetDailyTracking()
        print("Daily time goal tracking has been reset")
    }

    // Check if midnight reset is properly scheduled
    func verifyMidnightReset() -> Bool {
        return timeGoalService.hasMidnightResetScheduled()
    }
}
*/
