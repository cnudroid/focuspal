//
//  CategoryServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the category service interface.
/// Manages category CRUD operations and provides category data.
protocol CategoryServiceProtocol {
    /// Fetch all categories for a child
    func fetchCategories(for child: Child) async throws -> [Category]

    /// Fetch active categories only
    func fetchActiveCategories(for child: Child) async throws -> [Category]

    /// Create a new category
    func createCategory(_ category: Category) async throws -> Category

    /// Update an existing category
    func updateCategory(_ category: Category) async throws -> Category

    /// Delete a category (soft delete - sets isActive to false)
    func deleteCategory(_ categoryId: UUID) async throws

    /// Reorder categories
    func reorderCategories(_ categoryIds: [UUID]) async throws

    /// Create default system categories for a new child
    func createDefaultCategories(for child: Child) async throws -> [Category]
}
