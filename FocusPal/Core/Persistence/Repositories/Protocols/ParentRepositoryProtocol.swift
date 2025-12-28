//
//  ParentRepositoryProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol defining the parent repository interface.
/// Abstracts data access for Parent entities.
/// Note: This app supports a single parent profile.
protocol ParentRepositoryProtocol {
    /// Create a new parent profile
    func create(_ parent: Parent) async throws -> Parent

    /// Fetch the parent profile (single parent in this app)
    func fetch() async throws -> Parent?

    /// Update an existing parent profile
    func update(_ parent: Parent) async throws -> Parent

    /// Delete the parent profile
    func delete() async throws
}
