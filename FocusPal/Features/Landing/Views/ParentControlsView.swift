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
    var onAddChild: (() -> Void)?

    var body: some View {
        NavigationStack {
            List {
                // Child profiles section
                Section("Child Profiles") {
                    ForEach(viewModel.children) { child in
                        ChildManagementRow(child: child)
                    }

                    Button {
                        viewModel.showAddChild = true
                    } label: {
                        Label("Add Child Profile", systemImage: "plus.circle")
                    }
                }

                // Time goals section
                Section("Time Goals") {
                    NavigationLink {
                        TimeGoalsView()
                    } label: {
                        Label("Manage Time Goals", systemImage: "target")
                    }
                }

                // Categories section
                Section("Categories") {
                    NavigationLink {
                        CategorySettingsView()
                    } label: {
                        Label("Manage Categories", systemImage: "folder")
                    }
                }

                // Reports section
                Section("Reports") {
                    NavigationLink {
                        ReportsView()
                    } label: {
                        Label("View Reports", systemImage: "chart.xyaxis.line")
                    }
                }

                // PIN settings
                Section("Security") {
                    NavigationLink {
                        PINChangeView()
                    } label: {
                        Label("Change PIN", systemImage: "lock")
                    }
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
            }
            .sheet(isPresented: $viewModel.showAddChild) {
                AddChildView(onSave: {
                    Task {
                        await viewModel.loadChildren()
                        onAddChild?()
                    }
                })
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

#Preview {
    ParentControlsView()
}
