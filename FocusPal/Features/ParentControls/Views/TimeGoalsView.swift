//
//  TimeGoalsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for managing time goals per category.
struct TimeGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TimeGoalsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach($viewModel.goals) { $goal in
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
                                HStack {
                                    Text("Daily Limit:")
                                        .font(.subheadline)

                                    Spacer()

                                    Stepper(
                                        "\(goal.recommendedMinutes) min",
                                        value: $goal.recommendedMinutes,
                                        in: 15...240,
                                        step: 15
                                    )
                                    .fixedSize()
                                }
                                .padding(.leading, 40)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } footer: {
                    Text("Set daily time limits for each category. You'll receive notifications when approaching these goals.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Toggle categories on/off to track them")
                        Text("• Adjust stepper to set daily limits")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                } header: {
                    Label("How it works", systemImage: "info.circle.fill")
                }
            }
            .navigationTitle("Time Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.saveGoals()
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadGoals()
            }
        }
    }
}

/// ViewModel for TimeGoalsView that loads categories from shared storage
@MainActor
class TimeGoalsViewModel: ObservableObject {
    @Published var goals: [TimeGoalItem] = []

    private static let globalCategoryKey = "globalCategories"
    private static let timeGoalsKey = "timeGoals"

    func loadGoals() {
        // Load categories from shared storage
        var categories: [Category] = []

        if let data = UserDefaults.standard.data(forKey: Self.globalCategoryKey),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory() }
        } else {
            categories = Category.defaultCategories(for: nil)
        }

        // Load saved time goal settings
        let savedGoals = loadSavedGoalSettings()

        // Convert categories to TimeGoalItems, preserving saved settings
        goals = categories.map { category in
            if let saved = savedGoals[category.id] {
                return TimeGoalItem(
                    id: category.id,
                    categoryName: category.name,
                    iconName: category.iconName,
                    colorHex: category.colorHex,
                    recommendedMinutes: saved.minutes,
                    isActive: saved.isActive
                )
            } else {
                return TimeGoalItem(
                    id: category.id,
                    categoryName: category.name,
                    iconName: category.iconName,
                    colorHex: category.colorHex,
                    recommendedMinutes: category.durationMinutes,
                    isActive: true
                )
            }
        }
    }

    func saveGoals() {
        var settings: [String: TimeGoalSetting] = [:]
        for goal in goals {
            settings[goal.id.uuidString] = TimeGoalSetting(minutes: goal.recommendedMinutes, isActive: goal.isActive)
        }
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: Self.timeGoalsKey)
        }
    }

    private func loadSavedGoalSettings() -> [UUID: TimeGoalSetting] {
        guard let data = UserDefaults.standard.data(forKey: Self.timeGoalsKey),
              let decoded = try? JSONDecoder().decode([String: TimeGoalSetting].self, from: data) else {
            return [:]
        }
        var result: [UUID: TimeGoalSetting] = [:]
        for (key, value) in decoded {
            if let uuid = UUID(uuidString: key) {
                result[uuid] = value
            }
        }
        return result
    }
}

/// Saved time goal settings
private struct TimeGoalSetting: Codable {
    let minutes: Int
    let isActive: Bool
}

/// Codable wrapper for Category persistence (matches CategorySettingsViewModel)
private struct CategoryData: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let isSystem: Bool
    let recommendedDuration: TimeInterval

    func toCategory() -> Category {
        Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: sortOrder,
            isSystem: isSystem,
            childId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            recommendedDuration: recommendedDuration
        )
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
    let id: UUID
    let categoryName: String
    let iconName: String
    let colorHex: String
    var recommendedMinutes: Int
    var isActive: Bool

    init(id: UUID = UUID(), categoryName: String, iconName: String, colorHex: String, recommendedMinutes: Int, isActive: Bool) {
        self.id = id
        self.categoryName = categoryName
        self.iconName = iconName
        self.colorHex = colorHex
        self.recommendedMinutes = recommendedMinutes
        self.isActive = isActive
    }
}

#Preview {
    NavigationStack {
        TimeGoalsView()
    }
}
