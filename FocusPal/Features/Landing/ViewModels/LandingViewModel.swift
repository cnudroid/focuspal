//
//  LandingViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for the landing page.
/// Manages loading child profiles and navigation to parent controls.
@MainActor
class LandingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var children: [Child] = []
    @Published var selectedChild: Child?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showParentAuth = false
    @Published var showParentControls = false
    @Published var parentAuthSucceeded = false

    // MARK: - Dependencies

    private let childRepository: ChildRepositoryProtocol

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

            // Set active child if any
            if let activeChild = try await childRepository.fetchActiveChild() {
                selectedChild = activeChild
            }
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func selectChild(_ child: Child) async {
        do {
            try await childRepository.setActiveChild(child.id)
            selectedChild = child
        } catch {
            errorMessage = "Failed to select profile: \(error.localizedDescription)"
        }
    }
}

