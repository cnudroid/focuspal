//
//  TimeGoalsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for managing time goals per category.
struct TimeGoalsView: View {
    @State private var goals: [TimeGoalItem] = TimeGoalItem.sampleGoals

    var body: some View {
        List {
            Section {
                ForEach($goals) { $goal in
                    TimeGoalRow(goal: $goal)
                }
            } footer: {
                Text("Set recommended daily time limits for each category. You'll receive notifications when approaching these goals.")
            }
        }
        .navigationTitle("Time Goals")
    }
}

struct TimeGoalRow: View {
    @Binding var goal: TimeGoalItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.iconName)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: goal.colorHex))
                    .cornerRadius(6)

                Text(goal.categoryName)
                    .font(.headline)

                Spacer()

                Toggle("", isOn: $goal.isActive)
                    .labelsHidden()
            }

            if goal.isActive {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Limit: \(goal.recommendedMinutes) min")
                            .font(.subheadline)

                        Spacer()
                    }

                    Slider(
                        value: Binding(
                            get: { Double(goal.recommendedMinutes) },
                            set: { goal.recommendedMinutes = Int($0) }
                        ),
                        in: 15...240,
                        step: 15
                    )

                    HStack {
                        Text("15 min")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("4 hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 40)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimeGoalItem: Identifiable {
    let id = UUID()
    let categoryName: String
    let iconName: String
    let colorHex: String
    var recommendedMinutes: Int
    var isActive: Bool

    static let sampleGoals: [TimeGoalItem] = [
        TimeGoalItem(categoryName: "Homework", iconName: "book.fill", colorHex: "#4A90D9", recommendedMinutes: 60, isActive: true),
        TimeGoalItem(categoryName: "Reading", iconName: "text.book.closed.fill", colorHex: "#7B68EE", recommendedMinutes: 30, isActive: true),
        TimeGoalItem(categoryName: "Screen Time", iconName: "tv.fill", colorHex: "#FF6B6B", recommendedMinutes: 60, isActive: true),
        TimeGoalItem(categoryName: "Playing", iconName: "gamecontroller.fill", colorHex: "#4ECDC4", recommendedMinutes: 90, isActive: false),
        TimeGoalItem(categoryName: "Sports", iconName: "figure.run", colorHex: "#45B7D1", recommendedMinutes: 60, isActive: false)
    ]
}

#Preview {
    NavigationStack {
        TimeGoalsView()
    }
}
