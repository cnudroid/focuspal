//
//  TimerOverlayView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Full-screen timer overlay that wraps the existing TimerView.
/// Presented as a sheet from task cards and Siri navigation.
struct TimerOverlayView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    let currentChild: Child
    let initialCategoryId: UUID?
    let onDismiss: () -> Void

    @State private var timerIsRunning = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background (respects child preferences)
                ChildPreferenceBackground(child: currentChild, screenType: .timer)

                TimerView(
                timerManager: serviceContainer.multiChildTimerManager,
                activityService: serviceContainer.activityService,
                pointsService: serviceContainer.pointsService,
                rewardsService: serviceContainer.rewardsService,
                currentChild: currentChild
            )
            }
            .id(currentChild.id)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(timerIsRunning)
                    .opacity(timerIsRunning ? 0.5 : 1.0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(timerIsRunning)
        .onAppear {
            // Set the initial category if provided
            if let categoryId = initialCategoryId {
                serviceContainer.pendingTimerCategoryId = categoryId
            }
            // Auto-start if needed
            if serviceContainer.shouldAutoStartTimer {
                // The TimerView will handle auto-start via pendingTimerCategoryId
            }
        }
        .onReceive(serviceContainer.multiChildTimerManager.$activeTimers) { timers in
            // Check if the current child has an active timer
            timerIsRunning = timers.keys.contains(currentChild.id)
        }
    }
}

#Preview {
    TimerOverlayView(
        currentChild: Child(name: "Test", age: 8),
        initialCategoryId: nil,
        onDismiss: {}
    )
    .environmentObject(ServiceContainer())
}
