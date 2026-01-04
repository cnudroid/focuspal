//
//  ChildEntity.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents
import Foundation

/// AppEntity representing a Child profile for Siri integration.
/// Named SiriChildEntity to avoid conflict with Core Data ChildEntity.
@available(iOS 16.0, *)
struct SiriChildEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Child")
    static var defaultQuery = SiriChildEntityQuery()

    var id: UUID
    var name: String
    var age: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: UUID, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }

    init(from child: Child) {
        self.id = child.id
        self.name = child.name
        self.age = child.age
    }

    func toChild() -> Child {
        Child(id: id, name: name, age: age)
    }
}

/// Query for fetching SiriChildEntity instances for Siri.
@available(iOS 16.0, *)
struct SiriChildEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [SiriChildEntity] {
        let repository = CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        let allChildren = try await repository.fetchAll()
        return allChildren
            .filter { identifiers.contains($0.id) }
            .map { SiriChildEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [SiriChildEntity] {
        let repository = CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        let children = try await repository.fetchAll()
        return children.map { SiriChildEntity(from: $0) }
    }
}

/// String-based query for finding children by name.
@available(iOS 16.0, *)
extension SiriChildEntityQuery: EntityStringQuery {
    @MainActor
    func entities(matching string: String) async throws -> [SiriChildEntity] {
        let repository = CoreDataChildRepository(
            context: PersistenceController.shared.container.viewContext
        )
        let allChildren = try await repository.fetchAll()
        let lowercasedQuery = string.lowercased()
        return allChildren
            .filter { $0.name.lowercased().contains(lowercasedQuery) }
            .map { SiriChildEntity(from: $0) }
    }
}
