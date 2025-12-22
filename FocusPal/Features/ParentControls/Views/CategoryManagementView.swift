//
//  CategoryManagementView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for managing activity categories.
struct CategoryManagementView: View {
    @StateObject private var viewModel = CategoryManagementViewModel()
    @State private var showingAddCategory = false

    var body: some View {
        List {
            // System categories
            Section("Default Categories") {
                ForEach(viewModel.systemCategories) { category in
                    CategoryRow(category: category, isEditable: false)
                }
            }

            // Custom categories
            Section("Custom Categories") {
                ForEach(viewModel.customCategories) { category in
                    CategoryRow(category: category, isEditable: true)
                }
                .onDelete(perform: viewModel.deleteCategories)
                .onMove(perform: viewModel.moveCategories)

                Button {
                    showingAddCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadCategories()
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isEditable: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: category.colorHex))
                .cornerRadius(8)

            Text(category.name)

            Spacer()

            if !category.isActive {
                Text("Hidden")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddCategoryView: View {
    @ObservedObject var viewModel: CategoryManagementViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "circle.fill"
    @State private var selectedColor = "#4A90D9"

    let icons = ["book.fill", "tv.fill", "gamecontroller.fill", "figure.run", "music.note", "paintbrush.fill", "theatermasks.fill", "car.fill"]
    let colors = ["#4A90D9", "#7B68EE", "#FF6B6B", "#4ECDC4", "#45B7D1", "#F7DC6F", "#E74C3C", "#9B59B6"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor : Color(.systemGray5))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addCategory(
                                name: name,
                                icon: selectedIcon,
                                color: selectedColor
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryManagementView()
    }
}
