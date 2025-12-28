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
    @Published var hasParentProfile = false

    private let childRepository: ChildRepositoryProtocol
    private let parentRepository: ParentRepositoryProtocol

    init(childRepository: ChildRepositoryProtocol? = nil, parentRepository: ParentRepositoryProtocol? = nil) {
        self.childRepository = childRepository ?? CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        self.parentRepository = parentRepository ?? CoreDataParentRepository(
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

    func deleteChild(_ child: Child) async {
        do {
            try await childRepository.delete(child.id)
            children.removeAll { $0.id == child.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkParentProfile() async {
        do {
            let parent = try await parentRepository.fetch()
            hasParentProfile = parent != nil
        } catch {
            errorMessage = error.localizedDescription
            hasParentProfile = false
        }
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

/// ViewModel for editing an existing child profile.
@MainActor
class EditChildViewModel: ObservableObject {

    @Published var name: String
    @Published var age: Int
    @Published var selectedAvatar: String
    @Published var selectedTheme: String
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false

    private let childId: UUID
    private let childRepository: ChildRepositoryProtocol

    init(child: Child, childRepository: ChildRepositoryProtocol? = nil) {
        self.childId = child.id
        self.name = child.name
        self.age = child.age
        self.selectedAvatar = child.avatarId
        self.selectedTheme = child.themeColor
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

        let updatedChild = Child(
            id: childId,
            name: trimmedName,
            age: age,
            avatarId: selectedAvatar,
            themeColor: selectedTheme,
            isActive: true
        )

        do {
            _ = try await childRepository.update(updatedChild)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
