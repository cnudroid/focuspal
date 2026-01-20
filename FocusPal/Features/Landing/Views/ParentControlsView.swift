//
//  ParentControlsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Wrapper view for parent controls accessible from landing page.
struct ParentControlsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ParentControlsViewModel()
    @State private var childToEdit: Child?
    @State private var showTimeGoals = false
    @State private var showCategories = false
    @State private var showReports = false
    @State private var showPINChange = false
    @State private var showParentProfilePrompt = false
    @State private var selectedChildForSchedule: Child?
    @State private var selectedChildForStats: Child?
    @State private var selectedChildForLog: Child?
    @State private var selectedChildForReport: Child?
    var onAddChild: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                // Child profiles section
                Section("Child Profiles") {
                    ForEach(viewModel.children) { child in
                        Button {
                            childToEdit = child
                        } label: {
                            ChildManagementRow(child: child)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteChild(viewModel.children[index])
                            }
                            onAddChild?()
                        }
                    }

                    Button {
                        viewModel.showAddChild = true
                    } label: {
                        Label("Add Child Profile", systemImage: "plus.circle")
                    }
                }

                // Time goals section
                Section("Time Goals") {
                    Button {
                        showTimeGoals = true
                    } label: {
                        HStack {
                            Label("Manage Time Goals", systemImage: "target")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                }

                // Categories section
                Section("Categories") {
                    Button {
                        showCategories = true
                    } label: {
                        HStack {
                            Label("Manage Categories", systemImage: "folder")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                }

                // Per-child management sections
                ForEach(viewModel.children) { child in
                    Section(child.name) {
                        // Schedule
                        Button {
                            selectedChildForSchedule = child
                        } label: {
                            HStack {
                                Label("Schedule", systemImage: "calendar.badge.plus")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        // Statistics
                        Button {
                            selectedChildForStats = child
                        } label: {
                            HStack {
                                Label("Statistics", systemImage: "chart.bar.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        // Activity Log
                        Button {
                            selectedChildForLog = child
                        } label: {
                            HStack {
                                Label("Activity Log", systemImage: "list.bullet.clipboard")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        // Reports
                        Button {
                            selectedChildForReport = child
                        } label: {
                            HStack {
                                Label("Reports", systemImage: "chart.xyaxis.line")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }

                // Combined reports section (all children)
                if viewModel.children.count > 1 {
                    Section("All Children") {
                        Button {
                            showReports = true
                        } label: {
                            HStack {
                                Label("Combined Report", systemImage: "person.2.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }

                // PIN settings
                Section("Security") {
                    Button {
                        showPINChange = true
                    } label: {
                        HStack {
                            Label("Change PIN", systemImage: "lock")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Parent Controls")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadChildren()
                await checkAndShowParentProfilePrompt()
            }
            // All sub-views presented as sheets
            .sheet(isPresented: $viewModel.showAddChild) {
                AddChildView(onSave: {
                    Task {
                        await viewModel.loadChildren()
                        onAddChild?()
                    }
                })
            }
            .sheet(item: $childToEdit) { child in
                EditChildSheetView(
                    child: child,
                    onSave: {
                        Task {
                            await viewModel.loadChildren()
                            onAddChild?()
                        }
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteChild(child)
                            onAddChild?()
                        }
                    }
                )
            }
            .sheet(isPresented: $showTimeGoals) {
                TimeGoalsView()
            }
            .sheet(isPresented: $showCategories) {
                CategorySettingsView()
            }
            .sheet(isPresented: $showReports) {
                ReportsSheetView()
            }
            .sheet(isPresented: $showPINChange) {
                PINChangeSheetView()
            }
            .sheet(isPresented: $showParentProfilePrompt) {
                ParentProfilePromptView(onComplete: {
                    Task {
                        await viewModel.checkParentProfile()
                    }
                })
            }
            .sheet(item: $selectedChildForSchedule) { child in
                TaskSchedulerView(child: child)
            }
            .sheet(item: $selectedChildForStats) { child in
                StatisticsSheetView(child: child)
            }
            .sheet(item: $selectedChildForLog) { child in
                ActivityLogSheetView(child: child)
            }
            .sheet(item: $selectedChildForReport) { child in
                ChildReportSheetView(child: child)
            }
        }
    }

    // MARK: - Helper Methods

    /// Checks if parent profile exists and shows prompt if needed
    private func checkAndShowParentProfilePrompt() async {
        // Don't show if we've already shown it and user skipped
        let hasShownPrompt = UserDefaults.standard.bool(forKey: "hasShownParentProfilePrompt")
        if hasShownPrompt {
            return
        }

        // Check if parent profile exists
        await viewModel.checkParentProfile()

        // Show prompt if no parent profile exists
        if !viewModel.hasParentProfile {
            showParentProfilePrompt = true
        }
    }
}

// MARK: - Sheet Wrapper Views

struct EditChildSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let child: Child
    var onSave: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        NavigationStack {
            EditChildView(child: child, onSave: onSave, onDelete: onDelete)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct TimeGoalsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TimeGoalsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct CategorySettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CategorySettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ReportsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ReportsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct PINChangeSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PINChangeView()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct StatisticsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let child: Child

    var body: some View {
        NavigationStack {
            StatisticsView(currentChild: child)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ActivityLogSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let child: Child

    var body: some View {
        NavigationStack {
            ActivityLogView(currentChild: child)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ChildReportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var serviceContainer: ServiceContainer
    let child: Child

    var body: some View {
        NavigationStack {
            ReportsView(serviceContainer: serviceContainer, initialChild: child)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ChildManagementRow: View {
    let child: Child

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: child.avatarId.isEmpty ? "person.circle.fill" : child.avatarId)
                .font(.title)
                .foregroundColor(themeColor)

            VStack(alignment: .leading) {
                Text(child.name)
                    .font(.headline)

                Text("Age \(child.age)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var themeColor: Color {
        switch child.themeColor.lowercased() {
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

/// View for adding a new child profile
struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddChildViewModel()
    var onSave: (() -> Void)?

    let availableAvatars = [
        // Faces & People
        "person.circle.fill",
        "face.smiling.fill",
        "face.smiling.inverse",
        // Animals
        "hare.fill",
        "tortoise.fill",
        "bird.fill",
        "fish.fill",
        "pawprint.fill",
        "cat.fill",
        "dog.fill",
        // Fun & Playful
        "star.circle.fill",
        "heart.circle.fill",
        "bolt.circle.fill",
        "flame.circle.fill",
        "sparkles",
        "moon.stars.fill",
        "sun.max.fill",
        // Gaming & Sports
        "gamecontroller.fill",
        "figure.run",
        "basketball.fill",
        "soccerball",
        "tennisball.fill",
        // Fantasy
        "wand.and.stars",
        "crown.fill"
    ]

    let themeColors = ["blue", "pink", "green", "purple", "orange", "red", "teal", "yellow"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Info") {
                    TextField("Name", text: $viewModel.name)

                    Picker("Age", selection: $viewModel.age) {
                        ForEach(4...16, id: \.self) { age in
                            Text("\(age) years").tag(age)
                        }
                    }
                }

                Section("Theme Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(themeColors, id: \.self) { color in
                            Button {
                                viewModel.selectedTheme = color
                            } label: {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: viewModel.selectedTheme == color ? 3 : 0)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .opacity(viewModel.selectedTheme == color ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Avatar") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 55))], spacing: 12) {
                        ForEach(availableAvatars, id: \.self) { avatar in
                            Button {
                                viewModel.selectedAvatar = avatar
                            } label: {
                                Image(systemName: avatar)
                                    .font(.system(size: 32))
                                    .foregroundColor(viewModel.selectedAvatar == avatar ? selectedThemeColor : .gray)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(viewModel.selectedAvatar == avatar ? selectedThemeColor.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.selectedAvatar == avatar ? selectedThemeColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveChild()
                            onSave?()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var selectedThemeColor: Color {
        colorFor(viewModel.selectedTheme)
    }

    private func colorFor(_ theme: String) -> Color {
        switch theme.lowercased() {
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

/// View for editing an existing child profile
struct EditChildView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditChildViewModel
    var onSave: (() -> Void)?
    var onDelete: (() -> Void)?

    let availableAvatars = [
        "person.circle.fill", "face.smiling.fill", "face.smiling.inverse",
        "hare.fill", "tortoise.fill", "bird.fill", "fish.fill", "pawprint.fill", "cat.fill", "dog.fill",
        "star.circle.fill", "heart.circle.fill", "bolt.circle.fill", "flame.circle.fill",
        "sparkles", "moon.stars.fill", "sun.max.fill",
        "gamecontroller.fill", "figure.run", "basketball.fill", "soccerball", "tennisball.fill",
        "wand.and.stars", "crown.fill"
    ]

    let themeColors = ["blue", "pink", "green", "purple", "orange", "red", "teal", "yellow"]

    init(child: Child, onSave: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditChildViewModel(child: child))
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        Form {
            Section("Profile Info") {
                TextField("Name", text: $viewModel.name)

                Picker("Age", selection: $viewModel.age) {
                    ForEach(4...16, id: \.self) { age in
                        Text("\(age) years").tag(age)
                    }
                }
            }

            Section("Theme Color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                    ForEach(themeColors, id: \.self) { color in
                        Button {
                            viewModel.selectedTheme = color
                        } label: {
                            Circle()
                                .fill(colorFor(color))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: viewModel.selectedTheme == color ? 3 : 0)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .opacity(viewModel.selectedTheme == color ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Avatar") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 55))], spacing: 12) {
                    ForEach(availableAvatars, id: \.self) { avatar in
                        Button {
                            viewModel.selectedAvatar = avatar
                        } label: {
                            Image(systemName: avatar)
                                .font(.system(size: 32))
                                .foregroundColor(viewModel.selectedAvatar == avatar ? selectedThemeColor : .gray)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(viewModel.selectedAvatar == avatar ? selectedThemeColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.selectedAvatar == avatar ? selectedThemeColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Profile")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveChild()
                        onSave?()
                        dismiss()
                    }
                }
                .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .alert("Delete Profile?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("This will permanently delete \(viewModel.name)'s profile and all their activity data.")
        }
    }

    private var selectedThemeColor: Color {
        colorFor(viewModel.selectedTheme)
    }

    private func colorFor(_ theme: String) -> Color {
        switch theme.lowercased() {
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

#Preview {
    ParentControlsView()
}
