//
//  CategoryManagementViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for category management.
@MainActor
class CategoryManagementViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var systemCategories: [Category] = []
    @Published var customCategories: [Category] = []
    @Published var isLoading = false

    // MARK: - Dependencies

    private let categoryService: CategoryServiceProtocol

    // MARK: - Initialization

    init(categoryService: CategoryServiceProtocol? = nil) {
        self.categoryService = categoryService ?? MockCategoryServiceLocal()
    }

    // MARK: - Public Methods

    func loadCategories() async {
        isLoading = true

        // Mock data
        let mockChildId = UUID()

        systemCategories = [
            Category(name: "Homework", iconName: "book.fill", colorHex: "#4A90D9", isSystem: true, childId: mockChildId),
            Category(name: "Reading", iconName: "text.book.closed.fill", colorHex: "#7B68EE", isSystem: true, childId: mockChildId),
            Category(name: "Screen Time", iconName: "tv.fill", colorHex: "#FF6B6B", isSystem: true, childId: mockChildId),
            Category(name: "Playing", iconName: "gamecontroller.fill", colorHex: "#4ECDC4", isSystem: true, childId: mockChildId),
            Category(name: "Sports", iconName: "figure.run", colorHex: "#45B7D1", isSystem: true, childId: mockChildId),
            Category(name: "Music", iconName: "music.note", colorHex: "#F7DC6F", isSystem: true, childId: mockChildId)
        ]

        customCategories = [
            Category(name: "Art", iconName: "paintbrush.fill", colorHex: "#E74C3C", isSystem: false, childId: mockChildId)
        ]

        isLoading = false
    }

    func addCategory(name: String, icon: String, color: String) async {
        let mockChildId = UUID()
        let newCategory = Category(
            name: name,
            iconName: icon,
            colorHex: color,
            isSystem: false,
            childId: mockChildId
        )
        customCategories.append(newCategory)
    }

    func deleteCategories(at offsets: IndexSet) {
        customCategories.remove(atOffsets: offsets)
    }

    func moveCategories(from source: IndexSet, to destination: Int) {
        customCategories.move(fromOffsets: source, toOffset: destination)
    }
}

// Local mock
private class MockCategoryServiceLocal: CategoryServiceProtocol {
    func fetchCategories(for child: Child) async throws -> [Category] { [] }
    func fetchActiveCategories(for child: Child) async throws -> [Category] { [] }
    func createCategory(_ category: Category) async throws -> Category { category }
    func updateCategory(_ category: Category) async throws -> Category { category }
    func deleteCategory(_ categoryId: UUID) async throws { }
    func reorderCategories(_ categoryIds: [UUID]) async throws { }
    func createDefaultCategories(for child: Child) async throws -> [Category] { [] }
}
