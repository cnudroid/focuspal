//
//  ActivityEditView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for editing an existing activity
struct ActivityEditView: View {
    let activity: Activity
    let categoryName: String
    let categoryColor: String
    let onSave: (Activity) -> Void
    let onCancel: () -> Void

    @State private var durationMinutes: Int
    @State private var notes: String
    @State private var mood: Mood
    @State private var isComplete: Bool

    init(
        activity: Activity,
        categoryName: String,
        categoryColor: String,
        onSave: @escaping (Activity) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.activity = activity
        self.categoryName = categoryName
        self.categoryColor = categoryColor
        self.onSave = onSave
        self.onCancel = onCancel

        _durationMinutes = State(initialValue: activity.durationMinutes)
        _notes = State(initialValue: activity.notes ?? "")
        _mood = State(initialValue: activity.mood)
        _isComplete = State(initialValue: activity.isComplete)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Activity info (read-only)
                Section {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(categoryName)
                            .foregroundColor(Color(hex: categoryColor))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Date")
                        Spacer()
                        Text(activity.startTime, style: .date)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Time")
                        Spacer()
                        Text(formatTimeRange(start: activity.startTime, end: activity.endTime))
                            .foregroundColor(.secondary)
                    }
                }

                // Editable fields
                Section("Duration") {
                    Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 1...480, step: 5)
                }

                Section("Completion Status") {
                    Toggle("Completed", isOn: $isComplete)

                    if !isComplete {
                        Text("This activity will show as incomplete in your log")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Section("How did it go?") {
                    MoodPicker(selectedMood: $mood)
                }

                Section("Notes") {
                    TextField("Add notes about this activity...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                }
            }
        }
    }

    private func saveActivity() {
        // Calculate new end time based on duration change
        let newDuration = TimeInterval(durationMinutes * 60)
        let newEndTime = activity.startTime.addingTimeInterval(newDuration)

        let updatedActivity = Activity(
            id: activity.id,
            categoryId: activity.categoryId,
            childId: activity.childId,
            startTime: activity.startTime,
            endTime: newEndTime,
            notes: notes.isEmpty ? nil : notes,
            mood: mood,
            isManualEntry: activity.isManualEntry,
            isComplete: isComplete,
            createdDate: activity.createdDate,
            syncStatus: activity.syncStatus
        )

        onSave(updatedActivity)
    }

    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: Mood

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Mood.allCases.filter { $0 != .none }, id: \.self) { mood in
                Button {
                    selectedMood = mood
                } label: {
                    Text(mood.emoji)
                        .font(.title)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            Circle()
                                .stroke(selectedMood == mood ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }

            // None option
            Button {
                selectedMood = .none
            } label: {
                Text("Skip")
                    .font(.caption)
                    .foregroundColor(selectedMood == .none ? .blue : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedMood == .none ? Color.blue.opacity(0.2) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActivityEditView(
        activity: Activity(
            categoryId: UUID(),
            childId: UUID(),
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date(),
            isComplete: false
        ),
        categoryName: "Homework",
        categoryColor: "#4A90D9",
        onSave: { _ in },
        onCancel: { }
    )
}
