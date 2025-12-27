//
//  ParentControlsViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for parent controls view.
@MainActor
class ParentControlsViewModel: ObservableObject {

    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var showAddChild = false
    @Published var errorMessage: String?

    private let childRepository: ChildRepositoryProtocol

    init(childRepository: ChildRepositoryProtocol? = nil) {
        self.childRepository = childRepository ?? CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
    }

    func loadChildren() async {
        isLoading = true
        do {
            children = try await childRepository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// ViewModel for adding a new child profile.
@MainActor
class AddChildViewModel: ObservableObject {

    @Published var name = ""
    @Published var age = 8
    @Published var selectedAvatar = "person.circle.fill"
    @Published var selectedTheme = "blue"
    @Published var errorMessage: String?

    private let childRepository: ChildRepositoryProtocol

    init(childRepository: ChildRepositoryProtocol? = nil) {
        self.childRepository = childRepository ?? CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
    }

    func saveChild() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name"
            return
        }

        let child = Child(
            name: trimmedName,
            age: age,
            avatarId: selectedAvatar,
            themeColor: selectedTheme
        )

        do {
            _ = try await childRepository.create(child)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
