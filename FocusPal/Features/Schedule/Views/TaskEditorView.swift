//
//  TaskEditorView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for creating or editing a scheduled task.
struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let task: ScheduledTask?
    let categories: [Category]
    let onSave: (ScheduledTask) -> Void

    @State private var title: String = ""
    @State private var selectedCategoryId: UUID = UUID()
    @State private var scheduledDate: Date = Date()
    @State private var durationMinutes: Int = 25
    @State private var isRecurring: Bool = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .daily
    @State private var recurrenceInterval: Int = 1
    @State private var selectedDays: Set<Int> = []
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var reminderMinutes: Int = 5
    @State private var notes: String = ""

    private let durationOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]
    private let reminderOptions = [0, 5, 10, 15, 30, 60]

    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Task Details") {
                    TextField("Task title", text: $title)

                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(Color(hex: category.colorHex))
                                Text(category.name)
                            }
                            .tag(category.id)
                        }
                    }
                }

                // Schedule
                Section("Schedule") {
                    DatePicker("Date & Time", selection: $scheduledDate)

                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text(formatDuration(minutes)).tag(minutes)
                        }
                    }
                }

                // Recurrence
                Section {
                    Toggle("Recurring Task", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Frequency", selection: $recurrenceFrequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }

                        Stepper("Every \(recurrenceInterval) \(intervalUnitName)", value: $recurrenceInterval, in: 1...10)

                        if recurrenceFrequency == .weekly {
                            weekDayPicker
                        }

                        Toggle("Has End Date", isOn: $hasEndDate)

                        if hasEndDate {
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        }
                    }
                } header: {
                    Text("Recurrence")
                }

                // Reminder
                Section {
                    Picker("Reminder", selection: $reminderMinutes) {
                        ForEach(reminderOptions, id: \.self) { minutes in
                            Text(reminderText(for: minutes)).tag(minutes)
                        }
                    }
                } header: {
                    Text("Notification")
                } footer: {
                    Text("Get a notification before the task starts")
                }

                // Notes
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadTask()
            }
        }
    }

    private var weekDayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On Days")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    Button {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(dayAbbreviation(for: day))
                            .font(.caption.weight(.medium))
                            .frame(width: 36, height: 36)
                            .background(selectedDays.contains(day) ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var intervalUnitName: String {
        switch recurrenceFrequency {
        case .daily:
            return recurrenceInterval == 1 ? "day" : "days"
        case .weekly:
            return recurrenceInterval == 1 ? "week" : "weeks"
        case .monthly:
            return recurrenceInterval == 1 ? "month" : "months"
        }
    }

    private func dayAbbreviation(for day: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[day - 1]
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) minutes"
    }

    private func reminderText(for minutes: Int) -> String {
        if minutes == 0 {
            return "None"
        } else if minutes < 60 {
            return "\(minutes) minutes before"
        } else {
            return "\(minutes / 60) hour before"
        }
    }

    private func loadTask() {
        if let task = task {
            title = task.title
            selectedCategoryId = task.categoryId
            scheduledDate = task.scheduledDate
            durationMinutes = task.durationMinutes
            isRecurring = task.isRecurring
            reminderMinutes = task.reminderMinutesBefore
            notes = task.notes ?? ""

            if let rule = task.recurrenceRule {
                recurrenceFrequency = rule.frequency
                recurrenceInterval = rule.interval
                selectedDays = Set(rule.daysOfWeek ?? [])
                if let end = rule.endDate {
                    hasEndDate = true
                    endDate = end
                }
            }
        } else if let firstCategory = categories.first {
            selectedCategoryId = firstCategory.id
        }
    }

    private func saveTask() {
        var recurrenceRule: RecurrenceRule?
        if isRecurring {
            recurrenceRule = RecurrenceRule(
                frequency: recurrenceFrequency,
                interval: recurrenceInterval,
                daysOfWeek: recurrenceFrequency == .weekly ? Array(selectedDays) : nil,
                endDate: hasEndDate ? endDate : nil
            )
        }

        let savedTask = ScheduledTask(
            id: task?.id ?? UUID(),
            childId: task?.childId ?? UUID(),
            categoryId: selectedCategoryId,
            title: title.trimmingCharacters(in: .whitespaces),
            scheduledDate: scheduledDate,
            duration: TimeInterval(durationMinutes * 60),
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule,
            reminderMinutesBefore: reminderMinutes,
            isCompleted: task?.isCompleted ?? false,
            externalCalendarId: task?.externalCalendarId,
            calendarSource: task?.calendarSource ?? .app,
            notes: notes.isEmpty ? nil : notes,
            createdDate: task?.createdDate ?? Date()
        )

        onSave(savedTask)
        dismiss()
    }
}

#Preview {
    TaskEditorView(
        task: nil,
        categories: Category.defaultCategories(for: UUID()),
        onSave: { _ in }
    )
}
