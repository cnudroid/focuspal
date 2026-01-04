//
//  TaskSchedulerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent view for managing and scheduling tasks for children.
struct TaskSchedulerView: View {
    @StateObject private var viewModel: TaskSchedulerViewModel
    @State private var showingTaskEditor = false
    @State private var showingCalendarSync = false
    @State private var taskToEdit: ScheduledTask?

    init(child: Child, calendarService: CalendarServiceProtocol? = nil) {
        _viewModel = StateObject(wrappedValue: TaskSchedulerViewModel(
            calendarService: calendarService,
            child: child
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                // Calendar sync section
                Section {
                    Button {
                        showingCalendarSync = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Sync from Calendar")
                            Spacer()
                            if viewModel.isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Calendar Integration")
                }

                // Upcoming week
                Section {
                    ForEach(viewModel.upcomingDays, id: \.date) { day in
                        NavigationLink {
                            DayScheduleView(
                                date: day.date,
                                tasks: day.tasks,
                                onAddTask: { date in
                                    viewModel.addTaskForDate(date)
                                    showingTaskEditor = true
                                },
                                onEditTask: { task in
                                    taskToEdit = task
                                },
                                onDeleteTask: { task in
                                    Task { await viewModel.deleteTask(task) }
                                },
                                onCompleteTask: { task in
                                    Task { await viewModel.completeTask(task) }
                                }
                            )
                        } label: {
                            DayRow(day: day)
                        }
                    }
                } header: {
                    Text("This Week")
                }

                // Recurring tasks
                Section {
                    ForEach(viewModel.recurringTasks) { task in
                        RecurringTaskRow(task: task) {
                            taskToEdit = task
                        }
                    }

                    Button {
                        viewModel.addRecurringTask()
                        showingTaskEditor = true
                    } label: {
                        Label("Add Recurring Task", systemImage: "plus")
                    }
                } header: {
                    Text("Recurring Tasks")
                } footer: {
                    Text("Recurring tasks automatically appear on scheduled days")
                }
            }
            .navigationTitle("Schedule Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.addTaskForDate(Date())
                        showingTaskEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingTaskEditor) {
                TaskEditorView(
                    task: viewModel.taskBeingEdited,
                    categories: viewModel.categories,
                    onSave: { task in
                        Task { await viewModel.saveTask(task) }
                    }
                )
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditorView(
                    task: task,
                    categories: viewModel.categories,
                    onSave: { updatedTask in
                        Task { await viewModel.saveTask(updatedTask) }
                    }
                )
            }
            .sheet(isPresented: $showingCalendarSync) {
                CalendarSyncView(viewModel: viewModel)
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
}

// MARK: - Day Row

private struct DayRow: View {
    let day: TaskSchedulerViewModel.DaySchedule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.dayName)
                    .font(.headline)

                Text(day.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if day.tasks.isEmpty {
                Text("No tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Text("\(day.tasks.count)")
                        .font(.subheadline.weight(.medium))
                    Text(day.tasks.count == 1 ? "task" : "tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recurring Task Row

private struct RecurringTaskRow: View {
    let task: ScheduledTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))

                    if let rule = task.recurrenceRule {
                        Text(rule.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(task.scheduledDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Schedule View

private struct DayScheduleView: View {
    let date: Date
    let tasks: [ScheduledTask]
    let onAddTask: (Date) -> Void
    let onEditTask: (ScheduledTask) -> Void
    let onDeleteTask: (ScheduledTask) -> Void
    let onCompleteTask: (ScheduledTask) -> Void

    var body: some View {
        List {
            if tasks.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        Text("No tasks scheduled")
                            .font(.headline)

                        Button {
                            onAddTask(date)
                        } label: {
                            Label("Add Task", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                ForEach(tasks) { task in
                    TaskDetailRow(
                        task: task,
                        onEdit: { onEditTask(task) },
                        onComplete: { onCompleteTask(task) }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button {
                    onAddTask(date)
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .navigationTitle(formatDate(date))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct TaskDetailRow: View {
    let task: ScheduledTask
    let onEdit: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Text(task.timeRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if task.isRecurring {
                        Label("Recurring", systemImage: "repeat")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Calendar Sync View

private struct CalendarSyncView: View {
    @ObservedObject var viewModel: TaskSchedulerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.calendarAccessStatus == .authorized {
                    Section {
                        ForEach(viewModel.availableCalendars) { calendar in
                            CalendarRow(calendar: calendar) {
                                Task {
                                    await viewModel.syncCalendar(calendar)
                                }
                            }
                        }
                    } header: {
                        Text("Available Calendars")
                    } footer: {
                        Text("Select a calendar to import events as scheduled tasks")
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)

                            Text("Calendar access required")
                                .font(.headline)

                            Text("Grant calendar access to sync events")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button {
                                Task {
                                    await viewModel.requestCalendarAccess()
                                }
                            } label: {
                                Text("Grant Access")
                                    .font(.subheadline.weight(.medium))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                if viewModel.calendarAccessStatus == .authorized {
                    await viewModel.loadCalendars()
                }
            }
        }
    }
}

private struct CalendarRow: View {
    let calendar: ExternalCalendar
    let onSync: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: calendar.colorHex))
                .frame(width: 12, height: 12)

            Text(calendar.title)

            Spacer()

            Button("Sync", action: onSync)
                .font(.subheadline)
        }
    }
}

#Preview {
    TaskSchedulerView(child: Child(name: "Test", age: 8))
}
