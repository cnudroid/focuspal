//
//  CategorySettingsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent view for managing activity categories and their timer durations.
struct CategorySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CategorySettingsViewModel()
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?

    var body: some View {
        NavigationStack {
            Form {
                // Categories list
                Section {
                    ForEach(viewModel.categories) { category in
                        Button {
                            categoryToEdit = category
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: category.iconName)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color(hex: category.colorHex))
                                    .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(category.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        if category.isSystem {
                                            Text("SYSTEM")
                                                .font(.caption2)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text("\(category.durationMinutes) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Activity Categories")
                } footer: {
                    Text("Tap a category to edit its timer duration.")
                }

                // Add button
                Section {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add New Category", systemImage: "plus.circle.fill")
                    }
                }

                // Tips
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Tap a category to edit settings")
                        Text("• System categories cannot be deleted")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                } header: {
                    Label("Tips", systemImage: "lightbulb.fill")
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
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
    }
}

/// Card view for displaying a single category
struct CategoryCardView: View {
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
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CategorySettingsView()
    }
}
