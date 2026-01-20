//
//  CategoryManagementView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for managing activity categories.
struct CategoryManagementView: View {
    @EnvironmentObject private var serviceContainer: ServiceContainer
    @StateObject private var viewModel: CategoryManagementViewModel
    @State private var showingAddCategory = false

    init() {
        // Placeholder - will be replaced with real services via environment
        _viewModel = StateObject(wrappedValue: CategoryManagementViewModel(
            categoryService: PlaceholderCategoryService(),
            childRepository: PlaceholderChildRepository()
        ))
    }

    init(serviceContainer: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: CategoryManagementViewModel(
            categoryService: serviceContainer.categoryService,
            childRepository: serviceContainer.childRepository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading categories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.loadCategories() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                categoryList
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

    private var categoryList: some View {
        List {
            // System categories
            Section("Default Categories") {
                ForEach(viewModel.systemCategories) { category in
                    CategoryRow(category: category, isEditable: false, onToggleActive: {
                        Task { await viewModel.toggleCategoryActive(category) }
                    })
                }
            }

            // Custom categories
            Section("Custom Categories") {
                ForEach(viewModel.customCategories) { category in
                    CategoryRow(category: category, isEditable: true, onToggleActive: {
                        Task { await viewModel.toggleCategoryActive(category) }
                    })
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
    }
}

// Placeholder services for default init
private class PlaceholderCategoryService: CategoryServiceProtocol {
    func fetchCategories(for child: Child) async throws -> [Category] { [] }
    func fetchActiveCategories(for child: Child) async throws -> [Category] { [] }
    func createCategory(_ category: Category) async throws -> Category { category }
    func updateCategory(_ category: Category) async throws -> Category { category }
    func deleteCategory(_ categoryId: UUID) async throws { }
    func reorderCategories(_ categoryIds: [UUID]) async throws { }
    func createDefaultCategories(for child: Child) async throws -> [Category] { [] }
}

private class PlaceholderChildRepository: ChildRepositoryProtocol {
    func fetchAll() async throws -> [Child] { [] }
    func fetch(by id: UUID) async throws -> Child? { nil }
    func fetchActiveChild() async throws -> Child? { nil }
    func create(_ child: Child) async throws -> Child { child }
    func update(_ child: Child) async throws -> Child { child }
    func delete(_ id: UUID) async throws { }
    func setActiveChild(_ id: UUID) async throws { }
}

struct CategoryRow: View {
    let category: Category
    let isEditable: Bool
    var onToggleActive: (() -> Void)?

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
                Button {
                    onToggleActive?()
                } label: {
                    Text("Hidden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            } else if isEditable {
                Button {
                    onToggleActive?()
                } label: {
                    Image(systemName: "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
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
