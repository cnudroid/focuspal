//
//  ParentDashboardViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for the Parent Dashboard.
@MainActor
class ParentDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var children: [Child] = []
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var selectedChildIndex: Int = -1
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let childRepository: ChildRepositoryProtocol

    // MARK: - Computed Properties

    /// Get the currently selected child, or nil if "All Children" is selected
    var selectedChild: Child? {
        guard selectedChildIndex >= 0, selectedChildIndex < children.count else {
            return nil
        }
        return children[selectedChildIndex]
    }

    // MARK: - Initialization

    init(childRepository: ChildRepositoryProtocol? = nil) {
        self.childRepository = childRepository ?? CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
    }

    // MARK: - Public Methods

    func loadChildren() async {
        isLoading = true
        errorMessage = nil

        do {
            children = try await childRepository.fetchAll()
        } catch {
            errorMessage = "Failed to load children: \(error.localizedDescription)"
            children = []
        }

        isLoading = false
    }

    func addChildTapped() {
        // Navigate to add child flow
    }

    func authenticate() {
        isAuthenticated = true
    }
}
