//
//  TodayView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main Today tab view with mascot, task cards, and timer launch.
/// This is the primary kid-facing experience.
struct TodayView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: TodayViewModel
    let currentChild: Child
    let onStartTimer: (UUID?) -> Void

    @State private var showingCompletedSection = false

    init(
        currentChild: Child,
        onStartTimer: @escaping (UUID?) -> Void
    ) {
        self.currentChild = currentChild
        self.onStartTimer = onStartTimer
        _viewModel = StateObject(wrappedValue: TodayViewModel(child: currentChild))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background (respects child preferences)
                ChildPreferenceBackground(child: currentChild, screenType: .today)

                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Mascot greeting
                        ClockMascot(
                            size: 100,
                            message: viewModel.greetingMessage,
                            mood: viewModel.mascotMood
                        )
                        .padding(.top, 8)

                        // Today's points summary
                        TodayPointsSummary(points: viewModel.pointsEarnedToday)
                            .padding(.horizontal)

                        // Active task section
                        if let activeTask = viewModel.activeTasks.first {
                            activeTaskSection(activeTask)
                        }

                        // Upcoming tasks section
                        if !viewModel.nextUpcomingTasks.isEmpty {
                            upcomingTasksSection
                        }

                        // Completed section (collapsible)
                        if !viewModel.completedTasks.isEmpty {
                            completedTasksSection
                        }

                        // Empty state when no tasks
                        if viewModel.todayTasks.isEmpty && !viewModel.isLoading {
                            emptyStateView
                        }

                        // Bottom padding for FAB
                        Spacer().frame(height: 80)
                    }
                    .padding(.vertical)
                }

                // Floating action button to start timer
                VStack {
                    Spacer()
                    startTimerFAB
                }
            }
            .navigationTitle("Today")
            .task {
                viewModel.pointsService = serviceContainer.pointsService
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Sections

    private func activeTaskSection(_ task: ScheduledTask) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text("Happening Now")
                    .font(.headline)
            }
            .padding(.horizontal)

            TaskCard(
                task: task,
                category: viewModel.category(for: task),
                isActive: true,
                onStart: {
                    onStartTimer(task.categoryId)
                },
                onComplete: {
                    Task { await viewModel.completeTask(task) }
                }
            )
            .padding(.horizontal)
        }
    }

    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Coming Up")
                    .font(.headline)

                Spacer()

                if viewModel.upcomingTasks.count > 3 {
                    Text("+\(viewModel.upcomingTasks.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(viewModel.nextUpcomingTasks) { task in
                    CompactTaskCard(
                        task: task,
                        category: viewModel.category(for: task),
                        onTap: {
                            onStartTimer(task.categoryId)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var completedTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    showingCompletedSection.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Today's Wins")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("(\(viewModel.completedTasks.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: showingCompletedSection ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)

            if showingCompletedSection {
                VStack(spacing: 8) {
                    ForEach(viewModel.completedTasks) { task in
                        CompletedTaskRow(
                            task: task,
                            category: viewModel.category(for: task)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No tasks for today!")
                .font(.headline)

            Text("Tap the button below to start a focus session")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var startTimerFAB: some View {
        Button {
            onStartTimer(nil)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("Start Timer")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(BounceButtonStyle())
        .padding(.bottom, 16)
    }
}

// MARK: - Today Points Summary

struct TodayPointsSummary: View {
    let points: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Points")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(points)")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Streak indicator (placeholder)
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Keep it up!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Completed Task Row

struct CompletedTaskRow: View {
    let task: ScheduledTask
    let category: Category?

    private var categoryColor: Color {
        if let hex = category?.colorHex {
            return Color(hex: hex)
        }
        return .green
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon (faded)
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: category?.iconName ?? "checkmark")
                    .font(.subheadline)
                    .foregroundColor(categoryColor.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough()
                    .foregroundColor(.secondary)

                Text(task.scheduledDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground).opacity(0.5))
        )
    }
}

#Preview {
    TodayView(
        currentChild: Child(name: "Emma", age: 8),
        onStartTimer: { _ in }
    )
    .environmentObject(ServiceContainer())
}
