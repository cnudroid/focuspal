//
//  CategorySettingsViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Combine

/// ViewModel for managing category settings.
@MainActor
class CategorySettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let childId: UUID

    // MARK: - Initialization

    init(childId: UUID = UUID()) {
        self.childId = childId
        // Load default categories for now
        loadDefaultCategories()
    }

    // MARK: - Public Methods

    func loadCategories() async {
        isLoading = true
        // For now, use default categories
        // In production, this would fetch from Core Data
        loadDefaultCategories()
        isLoading = false
    }

    func addCategory(_ category: Category) {
        var newCategory = category
        newCategory = Category(
            id: category.id,
            name: category.name,
            iconName: category.iconName,
            colorHex: category.colorHex,
            isActive: category.isActive,
            sortOrder: categories.count,
            isSystem: false,
            parentCategoryId: category.parentCategoryId,
            childId: childId,
            recommendedDuration: category.recommendedDuration
        )
        categories.append(newCategory)
        saveCategories()
    }

    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        // Update sort orders
        for (index, _) in categories.enumerated() {
            categories[index] = Category(
                id: categories[index].id,
                name: categories[index].name,
                iconName: categories[index].iconName,
                colorHex: categories[index].colorHex,
                isActive: categories[index].isActive,
                sortOrder: index,
                isSystem: categories[index].isSystem,
                parentCategoryId: categories[index].parentCategoryId,
                childId: categories[index].childId,
                recommendedDuration: categories[index].recommendedDuration
            )
        }
        saveCategories()
    }

    // MARK: - Private Methods

    private func loadDefaultCategories() {
        // Check UserDefaults for saved categories first
        if let data = UserDefaults.standard.data(forKey: "savedCategories_\(childId.uuidString)"),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded.map { $0.toCategory(childId: childId) }
        } else {
            categories = Category.defaultCategories(for: childId)
        }
    }

    private func saveCategories() {
        let categoryData = categories.map { CategoryData(from: $0) }
        if let encoded = try? JSONEncoder().encode(categoryData) {
            UserDefaults.standard.set(encoded, forKey: "savedCategories_\(childId.uuidString)")
        }
    }
}

/// Codable wrapper for Category persistence
private struct CategoryData: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let isSystem: Bool
    let recommendedDuration: TimeInterval

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconName = category.iconName
        self.colorHex = category.colorHex
        self.isActive = category.isActive
        self.sortOrder = category.sortOrder
        self.isSystem = category.isSystem
        self.recommendedDuration = category.recommendedDuration
    }

    func toCategory(childId: UUID) -> Category {
        Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: sortOrder,
            isSystem: isSystem,
            childId: childId,
            recommendedDuration: recommendedDuration
        )
    }
}
