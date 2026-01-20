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
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let categoryService: CategoryServiceProtocol
    private let childRepository: ChildRepositoryProtocol
    private var currentChild: Child?

    // MARK: - Initialization

    init(
        categoryService: CategoryServiceProtocol,
        childRepository: ChildRepositoryProtocol
    ) {
        self.categoryService = categoryService
        self.childRepository = childRepository
    }

    // MARK: - Public Methods

    func loadCategories() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get the active child
            guard let child = try await childRepository.fetchActiveChild() else {
                // If no active child, try to get first child
                let allChildren = try await childRepository.fetchAll()
                guard let firstChild = allChildren.first else {
                    errorMessage = "No child profile found. Please create a child profile first."
                    isLoading = false
                    return
                }
                currentChild = firstChild
                await loadCategoriesForChild(firstChild)
                return
            }

            currentChild = child
            await loadCategoriesForChild(child)
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func loadCategoriesForChild(_ child: Child) async {
        do {
            let allCategories = try await categoryService.fetchCategories(for: child)

            // Separate system and custom categories
            systemCategories = allCategories.filter { $0.isSystem }.sorted { $0.sortOrder < $1.sortOrder }
            customCategories = allCategories.filter { !$0.isSystem }.sorted { $0.sortOrder < $1.sortOrder }

            // If no categories exist, create defaults
            if allCategories.isEmpty {
                let defaults = try await categoryService.createDefaultCategories(for: child)
                systemCategories = defaults.filter { $0.isSystem }.sorted { $0.sortOrder < $1.sortOrder }
                customCategories = defaults.filter { !$0.isSystem }.sorted { $0.sortOrder < $1.sortOrder }
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func addCategory(name: String, icon: String, color: String) async {
        guard let child = currentChild else {
            errorMessage = "No child profile selected"
            return
        }

        let newCategory = Category(
            name: name,
            iconName: icon,
            colorHex: color,
            sortOrder: customCategories.count,
            isSystem: false,
            childId: child.id
        )

        do {
            let created = try await categoryService.createCategory(newCategory)
            customCategories.append(created)
        } catch {
            errorMessage = "Failed to add category: \(error.localizedDescription)"
        }
    }

    func deleteCategories(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { customCategories[$0] }

        Task {
            for category in categoriesToDelete {
                do {
                    try await categoryService.deleteCategory(category.id)
                } catch {
                    errorMessage = "Failed to delete category: \(error.localizedDescription)"
                }
            }
            // Update local state
            customCategories.remove(atOffsets: offsets)
        }
    }

    func moveCategories(from source: IndexSet, to destination: Int) {
        customCategories.move(fromOffsets: source, toOffset: destination)

        // Persist the new order
        let categoryIds = customCategories.map { $0.id }
        Task {
            do {
                try await categoryService.reorderCategories(categoryIds)
            } catch {
                errorMessage = "Failed to reorder categories: \(error.localizedDescription)"
            }
        }
    }

    func toggleCategoryActive(_ category: Category) async {
        var updatedCategory = category
        updatedCategory.isActive.toggle()

        do {
            let saved = try await categoryService.updateCategory(updatedCategory)

            // Update local state
            if category.isSystem {
                if let index = systemCategories.firstIndex(where: { $0.id == category.id }) {
                    systemCategories[index] = saved
                }
            } else {
                if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
                    customCategories[index] = saved
                }
            }
        } catch {
            errorMessage = "Failed to update category: \(error.localizedDescription)"
        }
    }
}
