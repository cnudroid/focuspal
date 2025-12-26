//
//  ProfileSelectionView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for selecting between child profiles.
struct ProfileSelectionView: View {
    @StateObject private var viewModel: ProfileSelectionViewModel
    @Environment(\.dismiss) private var dismiss

    init(childRepository: ChildRepositoryProtocol? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileSelectionViewModel(childRepository: childRepository))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Who's using FocusPal?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                // Profile grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(viewModel.children) { child in
                        ProfileCard(
                            child: child,
                            isSelected: viewModel.isChildSelected(child),
                            onSelect: {
                                Task {
                                    await viewModel.selectChild(child)
                                    dismiss()
                                }
                            },
                            onEdit: {
                                viewModel.startEditingChild(child)
                            },
                            onDelete: {
                                viewModel.startDeleteChild(child)
                            }
                        )
                    }

                    // Add profile button (parent only)
                    if viewModel.canAddMoreChildren {
                        AddProfileCard {
                            viewModel.showAddProfile = true
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadChildren()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Delete Profile", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.confirmDelete()
                    }
                }
            } message: {
                if let child = viewModel.childToDelete {
                    Text("Are you sure you want to delete \(child.name)'s profile? This action cannot be undone.")
                }
            }
            .sheet(isPresented: $viewModel.showAddProfile) {
                // Add profile flow
                Text("Add Child Profile")
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                // Edit profile flow
                if let childToEdit = viewModel.childToEdit {
                    Text("Edit \(childToEdit.name)'s Profile")
                }
            }
        }
    }
}

struct ProfileCard: View {
    let child: Child
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: colorHex(for: child.themeColor)))

                Text(child.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Age \(child.age)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? Color(hex: colorHex(for: child.themeColor)).opacity(0.15) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: colorHex(for: child.themeColor)) : Color.clear, lineWidth: 3)
            )
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func colorHex(for theme: String) -> String {
        switch theme {
        case "pink": return "#FF69B4"
        case "blue": return "#4A90D9"
        case "green": return "#4CAF50"
        case "purple": return "#9C27B0"
        default: return "#888888"
        }
    }
}

struct AddProfileCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text("Add Child")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
}

#Preview {
    ProfileSelectionView()
}
