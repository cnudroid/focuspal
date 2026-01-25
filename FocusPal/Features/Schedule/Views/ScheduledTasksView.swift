//
//  ScheduledTasksView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main view for displaying today's scheduled tasks for the child.
struct ScheduledTasksView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: ScheduleViewModel
    @Binding var selectedTab: AppTab
    @State private var showingDatePicker = false
    @State private var selectedTaskForDetail: ScheduledTask?
    let child: Child

    init(child: Child, selectedTab: Binding<AppTab>, calendarService: CalendarServiceProtocol? = nil) {
        self.child = child
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: ScheduleViewModel(
            calendarService: calendarService,
            child: child
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date selector
                    dateHeader

                    // Calendar access prompt if needed
                    if viewModel.calendarAccessStatus == .notDetermined {
                        calendarAccessPrompt
                    }

                    // Active task highlight
                    if let activeTask = viewModel.activeTasks.first {
                        ActiveTaskCard(
                            task: activeTask,
                            onTap: {
                                selectedTaskForDetail = activeTask
                            },
                            onComplete: {
                                Task { await viewModel.completeTask(activeTask) }
                            }
                        )
                        .padding(.horizontal)
                    }

                    // Overdue tasks warning
                    if !viewModel.overdueTasks.isEmpty {
                        OverdueTasksSection(
                            tasks: viewModel.overdueTasks,
                            onComplete: { task in
                                Task { await viewModel.completeTask(task) }
                            }
                        )
                    }

                    // Tasks by time slot
                    ForEach(viewModel.tasksByTimeSlot, id: \.0) { slot, tasks in
                        TaskTimeSlotSection(
                            title: slot,
                            tasks: tasks,
                            onComplete: { task in
                                Task { await viewModel.completeTask(task) }
                            },
                            onTap: { task in
                                viewModel.editTask(task)
                            }
                        )
                    }

                    // Completed tasks
                    if !viewModel.completedTasks.isEmpty {
                        CompletedTasksSection(tasks: viewModel.completedTasks)
                    }

                    // Empty state
                    if viewModel.todayTasks.isEmpty && !viewModel.isLoading {
                        EmptyScheduleView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Today's Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .task {
                await viewModel.loadTasks()
            }
            .refreshable {
                await viewModel.loadTasks()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
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
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.selectedDate) {
                    Task {
                        await viewModel.loadTasks()
                    }
                    showingDatePicker = false
                }
            }
            .sheet(item: $selectedTaskForDetail) { task in
                TaskDetailSheet(
                    task: task,
                    onStartTimer: {
                        serviceContainer.pendingTimerCategoryId = task.categoryId
                        selectedTaskForDetail = nil
                        serviceContainer.pendingTimerOverlay = true
                    },
                    onComplete: {
                        Task {
                            await viewModel.completeTask(task)
                            selectedTaskForDetail = nil
                        }
                    },
                    onDismiss: {
                        selectedTaskForDetail = nil
                    }
                )
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selectedDate, style: .date)
                    .font(.title2.weight(.bold))

                Text(dayDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Quick nav buttons
            HStack(spacing: 12) {
                Button {
                    Task {
                        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate)!
                        await viewModel.loadTasksForDate(yesterday)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }

                Button {
                    Task {
                        await viewModel.loadTasksForDate(Date())
                    }
                } label: {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                }

                Button {
                    Task {
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate)!
                        await viewModel.loadTasksForDate(tomorrow)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var dayDescription: String {
        if Calendar.current.isDateInToday(viewModel.selectedDate) {
            let pendingCount = viewModel.pendingTasks.count
            if pendingCount == 0 {
                return "All done for today!"
            }
            return "\(pendingCount) task\(pendingCount == 1 ? "" : "s") remaining"
        } else if Calendar.current.isDateInYesterday(viewModel.selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(viewModel.selectedDate) {
            return "Tomorrow"
        }
        return ""
    }

    private var calendarAccessPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("Sync with Calendar")
                .font(.headline)

            Text("Connect your calendar to automatically add scheduled activities")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.requestCalendarAccess()
                }
            } label: {
                Text("Enable Calendar Access")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

private struct ActiveTaskCard: View {
    let task: ScheduledTask
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HAPPENING NOW")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white.opacity(0.8))

                        Text(task.title)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)

                        Text(task.timeRangeString)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    Button(action: onComplete) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * progressPercentage, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var progressPercentage: Double {
        let now = Date()
        let elapsed = now.timeIntervalSince(task.scheduledDate)
        return min(max(elapsed / task.duration, 0), 1)
    }
}

private struct OverdueTasksSection: View {
    let tasks: [ScheduledTask]
    let onComplete: (ScheduledTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Overdue")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)

            ForEach(tasks) { task in
                ScheduledTaskRow(
                    task: task,
                    isOverdue: true,
                    onComplete: { onComplete(task) },
                    onTap: {}
                )
            }
        }
    }
}

private struct TaskTimeSlotSection: View {
    let title: String
    let tasks: [ScheduledTask]
    let onComplete: (ScheduledTask) -> Void
    let onTap: (ScheduledTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(tasks) { task in
                ScheduledTaskRow(
                    task: task,
                    isOverdue: false,
                    onComplete: { onComplete(task) },
                    onTap: { onTap(task) }
                )
            }
        }
    }
}

private struct ScheduledTaskRow: View {
    let task: ScheduledTask
    let isOverdue: Bool
    let onComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    Text(task.scheduledDate, style: .time)
                        .font(.subheadline.weight(.medium))
                    Text("\(task.durationMinutes)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)

                // Vertical line
                Rectangle()
                    .fill(isOverdue ? Color.orange : (task.isUpcoming ? Color.gray : Color.blue))
                    .frame(width: 3)
                    .cornerRadius(1.5)

                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if task.isRecurring {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                Text(task.recurrenceRule?.description ?? "Recurring")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        // Show "Upcoming" label for future tasks
                        if task.isUpcoming {
                            Text("Upcoming")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                // Complete button - only show for tasks that can be completed (active or overdue)
                if task.canBeCompletedByChild {
                    Button(action: onComplete) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                } else if task.isUpcoming {
                    // Show clock icon for future tasks
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                }

                // Source indicator
                if task.calendarSource != .app {
                    Image(systemName: task.calendarSource.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

private struct CompletedTasksSection: View {
    let tasks: [ScheduledTask]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed (\(tasks.count))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(tasks) { task in
                    HStack(spacing: 12) {
                        Text(task.scheduledDate, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)

                        Text(task.title)
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundColor(.secondary)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct EmptyScheduleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Tasks Scheduled")
                .font(.headline)

            Text("Ask a parent to add some tasks or sync from your calendar")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Task Detail Sheet

private struct TaskDetailSheet: View {
    let task: ScheduledTask
    let onStartTimer: () -> Void
    let onComplete: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Task status indicator
                statusBadge
                    .padding(.top, 8)

                // Task info
                VStack(spacing: 8) {
                    Text(task.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(task.timeRangeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if task.isRecurring, let rule = task.recurrenceRule {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                            Text(rule.description)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                // Duration info
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(task.durationMinutes)")
                            .font(.title.weight(.bold))
                        Text("minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if task.isActive {
                        VStack(spacing: 4) {
                            Text("\(remainingMinutes)")
                                .font(.title.weight(.bold))
                                .foregroundColor(.orange)
                            Text("remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Notes if any
                if let notes = task.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if !task.isInstanceCompleted {
                        // Only show Start Timer for active or upcoming tasks (not overdue)
                        if task.isActive || task.isUpcoming {
                            Button(action: onStartTimer) {
                                Label("Start Timer", systemImage: "timer")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }

                        // Only show Mark Complete for tasks child can complete (active or overdue)
                        if task.canBeCompletedByChild {
                            Button(action: onComplete) {
                                Label("Mark Complete", systemImage: "checkmark.circle")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        } else if task.isUpcoming {
                            // Show info text for future tasks
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text("Complete this when it's time!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Task Completed")
                                .font(.headline)
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var statusBadge: some View {
        Group {
            if task.isCompleted {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(16)
            } else if task.isActive {
                Label("Happening Now", systemImage: "clock.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(16)
            } else if task.isOverdue {
                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(16)
            } else {
                Label("Upcoming", systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
            }
        }
    }

    private var remainingMinutes: Int {
        let remaining = task.endDate.timeIntervalSinceNow
        return max(0, Int(remaining / 60))
    }
}

#Preview {
    ScheduledTasksView(
        child: Child(name: "Test", age: 8),
        selectedTab: .constant(.today),
        calendarService: MockCalendarService.withSampleTasks(for: Child(name: "Test", age: 8))
    )
    .environmentObject(ServiceContainer())
}
