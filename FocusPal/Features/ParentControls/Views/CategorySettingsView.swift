//
//  CategorySettingsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent view for managing activity categories and their timer durations.
struct CategorySettingsView: View {
    @StateObject private var viewModel = CategorySettingsViewModel()
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?

    var body: some View {
        List {
            // Categories list
            Section {
                ForEach(viewModel.categories) { category in
                    CategoryRowView(category: category) {
                        categoryToEdit = category
                    }
                }
                .onDelete(perform: deleteCategories)
                .onMove(perform: moveCategories)
            } header: {
                Text("Activity Categories")
            } footer: {
                Text("Set timer duration for each activity. Tap to edit.")
            }

            // Add button
            Section {
                Button {
                    showingAddCategory = true
                } label: {
                    Label("Add New Category", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorView(mode: .add) { newCategory in
                viewModel.addCategory(newCategory)
            }
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryEditorView(mode: .edit(category)) { updatedCategory in
                viewModel.updateCategory(updatedCategory)
            }
        }
        .task {
            await viewModel.loadCategories()
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = viewModel.categories[index]
            if !category.isSystem {
                viewModel.deleteCategory(category)
            }
        }
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        viewModel.moveCategories(from: source, to: destination)
    }
}

/// Row view for displaying a single category
struct CategoryRowView: View {
    let category: Category
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with color
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: category.colorHex))
                    .cornerRadius(10)

                // Name and duration
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(category.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if category.isSystem {
                            Text("SYSTEM")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    Text("\(category.durationMinutes) minutes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CategorySettingsView()
    }
}
