//
//  CategoryEditorView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Mode for the category editor
enum CategoryEditorMode: Identifiable {
    case add
    case edit(Category)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let category): return category.id.uuidString
        }
    }
}

/// View for adding or editing a category
struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: CategoryEditorMode
    let onSave: (Category) -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String = "book.fill"
    @State private var selectedColor: String = "#4A90D9"
    @State private var durationMinutes: Int = 25
    @State private var selectedCategoryType: CategoryType = .task
    @State private var pointsMultiplier: Double = 1.0

    private let durationOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]
    private let multiplierOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section("Category Name") {
                    TextField("Enter name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // Duration section
                Section {
                    Picker("Timer Duration", selection: $durationMinutes) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text(formatDuration(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Timer Duration")
                } footer: {
                    Text("How long should the timer run for this activity?")
                }

                // Category Type section
                Section {
                    Picker("Category Type", selection: $selectedCategoryType) {
                        Text("Task").tag(CategoryType.task)
                        Text("Reward").tag(CategoryType.reward)
                    }
                    .pickerStyle(.segmented)

                    // Explanation of selected type
                    HStack(spacing: 12) {
                        Image(systemName: selectedCategoryType.iconName)
                            .font(.title2)
                            .foregroundColor(selectedCategoryType == .task ? .green : .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedCategoryType == .task ? "Earns Points" : "Costs Points")
                                .font(.subheadline.weight(.medium))
                            Text(selectedCategoryType == .task
                                ? "Child earns points when they complete this activity"
                                : "Child spends points to start this activity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Category Type")
                }

                // Points Multiplier section
                Section {
                    Picker("Points Multiplier", selection: $pointsMultiplier) {
                        ForEach(multiplierOptions, id: \.self) { multiplier in
                            Text("\(multiplier, specifier: "%.2g")x").tag(multiplier)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Points Multiplier")
                } footer: {
                    if selectedCategoryType == .task {
                        Text("Points earned: \(Int(10 * pointsMultiplier)) per completion")
                    } else {
                        Text("Points cost: \(Int(10 * pointsMultiplier)) to start")
                    }
                }

                // Icon section
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(Category.availableIcons, id: \.self) { icon in
                            CategoryIconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon,
                                color: selectedColor
                            ) {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Color section
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Category.availableColors, id: \.self) { color in
                            CategoryColorButton(
                                color: color,
                                isSelected: selectedColor == color
                            ) {
                                selectedColor = color
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview section
                Section("Preview") {
                    HStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(hex: selectedColor))
                                .cornerRadius(10)

                            // Type indicator badge
                            Image(systemName: selectedCategoryType.iconName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(selectedCategoryType == .task ? Color.green : Color.orange)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(name.isEmpty ? "Category Name" : name)
                                    .font(.headline)
                                Text("(\(selectedCategoryType.displayName))")
                                    .font(.caption)
                                    .foregroundColor(selectedCategoryType == .task ? .green : .orange)
                            }
                            HStack(spacing: 8) {
                                Text("\(durationMinutes) min")
                                if pointsMultiplier != 1.0 {
                                    Text("\(pointsMultiplier, specifier: "%.2g")x pts")
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadExistingCategory()
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func loadExistingCategory() {
        if case .edit(let category) = mode {
            name = category.name
            selectedIcon = category.iconName
            selectedColor = category.colorHex
            durationMinutes = category.durationMinutes
            selectedCategoryType = category.categoryType
            pointsMultiplier = category.pointsMultiplier
        }
    }

    private func saveCategory() {
        let category: Category

        switch mode {
        case .add:
            category = Category(
                name: name.trimmingCharacters(in: .whitespaces),
                iconName: selectedIcon,
                colorHex: selectedColor,
                childId: UUID(),
                recommendedDuration: TimeInterval(durationMinutes * 60),
                categoryType: selectedCategoryType,
                pointsMultiplier: pointsMultiplier
            )
        case .edit(let existing):
            category = Category(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                iconName: selectedIcon,
                colorHex: selectedColor,
                isActive: existing.isActive,
                sortOrder: existing.sortOrder,
                isSystem: existing.isSystem,
                parentCategoryId: existing.parentCategoryId,
                childId: existing.childId,
                recommendedDuration: TimeInterval(durationMinutes * 60),
                categoryType: selectedCategoryType,
                pointsMultiplier: pointsMultiplier
            )
        }

        onSave(category)
        dismiss()
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
        return "\(minutes) minutes"
    }
}

/// Button for selecting an icon in category editor
struct CategoryIconButton: View {
    let icon: String
    let isSelected: Bool
    let color: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : Color(hex: color))
                .frame(width: 50, height: 50)
                .background(isSelected ? Color(hex: color) : Color(hex: color).opacity(0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color(hex: color).opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Button for selecting a color in category editor
struct CategoryColorButton: View {
    let color: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(Color(hex: color).opacity(0.5), lineWidth: isSelected ? 1 : 0)
                        .padding(-2)
                )
                .shadow(color: isSelected ? Color(hex: color).opacity(0.5) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Add") {
    CategoryEditorView(mode: .add) { _ in }
}

#Preview("Edit") {
    CategoryEditorView(
        mode: .edit(Category(
            name: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            childId: UUID(),
            recommendedDuration: 25 * 60
        ))
    ) { _ in }
}
