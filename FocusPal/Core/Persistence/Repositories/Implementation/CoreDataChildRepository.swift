//
//  CoreDataChildRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the child repository.
class CoreDataChildRepository: ChildRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - ChildRepositoryProtocol

    func create(_ child: Child) async throws -> Child {
        return try await context.perform {
            let entity = ChildEntity(context: self.context)
            self.mapToEntity(child, entity: entity)
            try self.context.save()
            return child
        }
    }

    func fetchAll() async throws -> [Child] {
        return try await context.perform {
            let request = ChildEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetch(by id: UUID) async throws -> Child? {
        return try await context.perform {
            let request = ChildEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func update(_ child: Child) async throws -> Child {
        return try await context.perform {
            let request = ChildEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", child.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.mapToEntity(child, entity: entity)
            try self.context.save()
            return child
        }
    }

    func delete(_ childId: UUID) async throws {
        try await context.perform {
            let request = ChildEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", childId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.context.delete(entity)
            try self.context.save()
        }
    }

    func fetchActiveChild() async throws -> Child? {
        return try await context.perform {
            let request = ChildEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func setActiveChild(_ childId: UUID) async throws {
        try await context.perform {
            // First, deactivate all children
            let allRequest = ChildEntity.fetchRequest()
            let allEntities = try self.context.fetch(allRequest)
            for entity in allEntities {
                entity.isActive = false
            }

            // Then activate the specified child
            let request = ChildEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", childId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            entity.isActive = true
            try self.context.save()
        }
    }

    // MARK: - Mapping

    private func mapToEntity(_ child: Child, entity: ChildEntity) {
        entity.id = child.id
        entity.name = child.name
        entity.age = Int16(child.age)
        entity.avatarId = child.avatarId
        entity.themeColor = child.themeColor
        entity.createdDate = child.createdDate
        entity.lastActiveDate = child.lastActiveDate
        entity.isActive = child.isActive

        if let preferencesData = try? JSONEncoder().encode(child.preferences) {
            entity.preferencesJSON = preferencesData
        }
    }

    private func mapFromEntity(_ entity: ChildEntity) -> Child {
        var preferences = ChildPreferences()
        if let data = entity.preferencesJSON,
           let decoded = try? JSONDecoder().decode(ChildPreferences.self, from: data) {
            preferences = decoded
        }

        return Child(
            id: entity.id,
            name: entity.name,
            age: Int(entity.age),
            avatarId: entity.avatarId,
            themeColor: entity.themeColor,
            preferences: preferences,
            createdDate: entity.createdDate,
            lastActiveDate: entity.lastActiveDate,
            isActive: entity.isActive
        )
    }
}

/// Common repository errors
enum RepositoryError: Error, LocalizedError {
    case entityNotFound
    case saveFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "The requested entity could not be found."
        case .saveFailed:
            return "Failed to save changes to the database."
        case .fetchFailed:
            return "Failed to fetch data from the database."
        }
    }
}
