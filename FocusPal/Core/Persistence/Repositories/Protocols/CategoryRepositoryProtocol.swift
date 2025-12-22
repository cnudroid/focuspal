//
//  CategoryRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the category repository interface.
/// Abstracts data access for Category entities.
protocol CategoryRepositoryProtocol {
    /// Create a new category
    func create(_ category: Category) async throws -> Category

    /// Fetch all categories for a child
    func fetchAll(for childId: UUID) async throws -> [Category]

    /// Fetch a specific category by ID
    func fetch(by id: UUID) async throws -> Category?

    /// Update an existing category
    func update(_ category: Category) async throws -> Category

    /// Delete a category
    func delete(_ categoryId: UUID) async throws

    /// Fetch system (default) categories
    func fetchSystemCategories(for childId: UUID) async throws -> [Category]

    /// Fetch custom (user-created) categories
    func fetchCustomCategories(for childId: UUID) async throws -> [Category]
}
