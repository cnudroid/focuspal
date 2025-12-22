//
//  ManualEntryView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Manual activity entry form with date, time, and duration inputs.
struct ManualEntryView: View {
    @ObservedObject var viewModel: ActivityLogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: Category?
    @State private var startDate = Date()
    @State private var duration: Int = 30
    @State private var notes = ""
    @State private var selectedMood: Mood = .none

    var body: some View {
        NavigationStack {
            Form {
                // Category section
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select").tag(nil as Category?)
                        ForEach(viewModel.categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }
                }

                // Time section
                Section("Time") {
                    DatePicker(
                        "Start Time",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Stepper(
                        "Duration: \(duration) minutes",
                        value: $duration,
                        in: 1...480,
                        step: 5
                    )
                }

                // Notes section
                Section("Notes (Optional)") {
                    TextField("Add notes about this activity...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Mood section
                Section("How did you feel?") {
                    HStack {
                        ForEach(Mood.allCases.filter { $0 != .none }, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood
                            ) {
                                selectedMood = mood
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(selectedCategory == nil)
                }
            }
        }
    }

    private func saveActivity() {
        guard let category = selectedCategory else { return }

        Task {
            await viewModel.logManualActivity(
                category: category,
                startTime: startDate,
                duration: TimeInterval(duration * 60),
                notes: notes.isEmpty ? nil : notes,
                mood: selectedMood
            )
            dismiss()
        }
    }
}

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(mood.emoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(25)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
    }
}

#Preview {
    ManualEntryView(viewModel: ActivityLogViewModel())
}
