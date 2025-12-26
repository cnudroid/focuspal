//
//  ProfileSelectionViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for profile selection.
@MainActor
class ProfileSelectionViewModel: ObservableObject {

    // MARK: - Constants

    private static let maxChildren = 5

    // MARK: - Published Properties

    @Published var children: [Child] = []
    @Published var selectedChild: Child?
    @Published var showAddProfile = false
    @Published var showEditProfile = false
    @Published var showDeleteConfirmation = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var childToEdit: Child?
    @Published var childToDelete: Child?

    // MARK: - Dependencies

    private let childRepository: ChildRepositoryProtocol

    // MARK: - Initialization

    init(childRepository: ChildRepositoryProtocol? = nil) {
        self.childRepository = childRepository ?? MockChildRepoLocal()
    }

    // MARK: - Public Computed Properties

    var canAddMoreChildren: Bool {
        children.count < Self.maxChildren
    }

    // MARK: - Public Methods

    /// Load all children from the repository
    func loadChildren() async {
        isLoading = true
        errorMessage = nil

        do {
            children = try await childRepository.fetchAll()

            // Load the currently active child
            if let activeChild = try await childRepository.fetchActiveChild() {
                selectedChild = activeChild
            }
        } catch {
            errorMessage = "Failed to load children: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Select a child and set as active
    func selectChild(_ child: Child) async {
        selectedChild = child
        errorMessage = nil

        do {
            try await childRepository.setActiveChild(child.id)
        } catch {
            errorMessage = "Failed to select child: \(error.localizedDescription)"
        }
    }

    /// Add a new child profile
    func addChild(_ child: Child) async {
        guard canAddMoreChildren else {
            errorMessage = "Cannot add more children. Maximum of \(Self.maxChildren) children allowed."
            return
        }

        errorMessage = nil

        do {
            let createdChild = try await childRepository.create(child)
            children.append(createdChild)
            showAddProfile = false
        } catch {
            errorMessage = "Failed to add child: \(error.localizedDescription)"
        }
    }

    /// Start editing a child profile
    func startEditingChild(_ child: Child) {
        childToEdit = child
        showEditProfile = true
    }

    /// Update a child profile
    func updateChild(_ child: Child) async {
        errorMessage = nil

        do {
            let updatedChild = try await childRepository.update(child)

            if let index = children.firstIndex(where: { $0.id == child.id }) {
                children[index] = updatedChild
            }

            showEditProfile = false
            childToEdit = nil
        } catch {
            errorMessage = "Failed to update child: \(error.localizedDescription)"
        }
    }

    /// Cancel editing
    func cancelEdit() {
        showEditProfile = false
        childToEdit = nil
    }

    /// Start deleting a child (show confirmation)
    func startDeleteChild(_ child: Child) {
        childToDelete = child
        showDeleteConfirmation = true
    }

    /// Confirm and delete a child
    func confirmDelete() async {
        guard let child = childToDelete else { return }

        errorMessage = nil

        do {
            try await childRepository.delete(child.id)
            children.removeAll { $0.id == child.id }

            // Clear selection if the deleted child was selected
            if selectedChild?.id == child.id {
                selectedChild = nil
            }

            showDeleteConfirmation = false
            childToDelete = nil
        } catch {
            errorMessage = "Failed to delete child: \(error.localizedDescription)"
            showDeleteConfirmation = false
        }
    }

    /// Cancel deletion
    func cancelDelete() {
        showDeleteConfirmation = false
        childToDelete = nil
    }

    /// Check if a child is currently selected
    func isChildSelected(_ child: Child) -> Bool {
        return selectedChild?.id == child.id
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

// Local mock
private class MockChildRepoLocal: ChildRepositoryProtocol {
    func create(_ child: Child) async throws -> Child { child }
    func fetchAll() async throws -> [Child] { [] }
    func fetch(by id: UUID) async throws -> Child? { nil }
    func update(_ child: Child) async throws -> Child { child }
    func delete(_ childId: UUID) async throws { }
    func fetchActiveChild() async throws -> Child? { nil }
    func setActiveChild(_ childId: UUID) async throws { }
}
