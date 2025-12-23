//
//  MockCategoryService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of CategoryService for testing and previews.
class MockCategoryService: CategoryServiceProtocol {

    // MARK: - Mock Data

    var mockCategories: [Category] = []
    var mockError: Error?

    // MARK: - CategoryServiceProtocol

    func fetchCategories(for child: Child) async throws -> [Category] {
        if let error = mockError {
            throw error
        }
        return mockCategories
    }

    func fetchActiveCategories(for child: Child) async throws -> [Category] {
        if let error = mockError {
            throw error
        }
        return mockCategories.filter { $0.isActive }
    }

    func createCategory(_ category: Category) async throws -> Category {
        if let error = mockError {
            throw error
        }
        mockCategories.append(category)
        return category
    }

    func updateCategory(_ category: Category) async throws -> Category {
        if let error = mockError {
            throw error
        }
        if let index = mockCategories.firstIndex(where: { $0.id == category.id }) {
            mockCategories[index] = category
        }
        return category
    }

    func deleteCategory(_ categoryId: UUID) async throws {
        if let error = mockError {
            throw error
        }
        mockCategories.removeAll { $0.id == categoryId }
    }

    func reorderCategories(_ categoryIds: [UUID]) async throws {
        if let error = mockError {
            throw error
        }
    }

    func createDefaultCategories(for child: Child) async throws -> [Category] {
        if let error = mockError {
            throw error
        }
        let defaults = Category.defaultCategories(for: child.id)
        mockCategories.append(contentsOf: defaults)
        return defaults
    }
}
