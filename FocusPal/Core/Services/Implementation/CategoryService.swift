//
//  CategoryService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Concrete implementation of the category service.
/// Manages category operations including CRUD and default category creation.
class CategoryService: CategoryServiceProtocol {

    // MARK: - Properties

    private let repository: CategoryRepositoryProtocol

    // MARK: - Initialization

    init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - CategoryServiceProtocol

    func fetchCategories(for child: Child) async throws -> [Category] {
        return try await repository.fetchAll(for: child.id)
    }

    func fetchActiveCategories(for child: Child) async throws -> [Category] {
        let allCategories = try await repository.fetchAll(for: child.id)
        return allCategories.filter { $0.isActive }
    }

    func createCategory(_ category: Category) async throws -> Category {
        return try await repository.create(category)
    }

    func updateCategory(_ category: Category) async throws -> Category {
        return try await repository.update(category)
    }

    func deleteCategory(_ categoryId: UUID) async throws {
        // Soft delete - fetch, update isActive, save
        guard var category = try await repository.fetch(by: categoryId) else {
            throw CategoryServiceError.categoryNotFound
        }

        category.isActive = false
        _ = try await repository.update(category)
    }

    func reorderCategories(_ categoryIds: [UUID]) async throws {
        for (index, categoryId) in categoryIds.enumerated() {
            guard var category = try await repository.fetch(by: categoryId) else {
                continue
            }
            category.sortOrder = index
            _ = try await repository.update(category)
        }
    }

    func createDefaultCategories(for child: Child) async throws -> [Category] {
        let defaultCategories = Category.defaultCategories(for: child.id)
        var createdCategories: [Category] = []

        for category in defaultCategories {
            let created = try await repository.create(category)
            createdCategories.append(created)
        }

        return createdCategories
    }
}

/// Errors that can occur in CategoryService
enum CategoryServiceError: Error, LocalizedError {
    case categoryNotFound
    case invalidCategory

    var errorDescription: String? {
        switch self {
        case .categoryNotFound:
            return "The requested category could not be found."
        case .invalidCategory:
            return "The category data is invalid."
        }
    }
}
