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

    // MARK: - Published Properties

    @Published var children: [Child] = []
    @Published var selectedChild: Child?
    @Published var showAddProfile = false
    @Published var isLoading = false

    // MARK: - Dependencies

    private let childRepository: ChildRepositoryProtocol

    // MARK: - Initialization

    init(childRepository: ChildRepositoryProtocol? = nil) {
        self.childRepository = childRepository ?? MockChildRepoLocal()
        loadChildren()
    }

    // MARK: - Public Methods

    func loadChildren() {
        // Mock data
        children = [
            Child(name: "Emma", age: 8, themeColor: "pink"),
            Child(name: "Lucas", age: 10, themeColor: "blue")
        ]
    }

    func selectChild(_ child: Child) {
        selectedChild = child

        Task {
            try? await childRepository.setActiveChild(child.id)
        }
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
