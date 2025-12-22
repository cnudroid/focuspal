//
//  ChildRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the child repository interface.
/// Abstracts data access for Child entities.
protocol ChildRepositoryProtocol {
    /// Create a new child profile
    func create(_ child: Child) async throws -> Child

    /// Fetch all child profiles
    func fetchAll() async throws -> [Child]

    /// Fetch a specific child by ID
    func fetch(by id: UUID) async throws -> Child?

    /// Update an existing child profile
    func update(_ child: Child) async throws -> Child

    /// Delete a child profile
    func delete(_ childId: UUID) async throws

    /// Fetch the currently active child
    func fetchActiveChild() async throws -> Child?

    /// Set a child as the active profile
    func setActiveChild(_ childId: UUID) async throws
}
