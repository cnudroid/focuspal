//
//  CoreDataParentRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the parent repository.
/// Manages persistence for the single parent profile in the app.
class CoreDataParentRepository: ParentRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - ParentRepositoryProtocol

    func create(_ parent: Parent) async throws -> Parent {
        return try await context.perform {
            let entity = ParentEntity(context: self.context)
            self.mapToEntity(parent, entity: entity)
            try self.context.save()
            return parent
        }
    }

    func fetch() async throws -> Parent? {
        return try await context.perform {
            let request = ParentEntity.fetchRequest()
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func update(_ parent: Parent) async throws -> Parent {
        return try await context.perform {
            let request = ParentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", parent.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.mapToEntity(parent, entity: entity)
            try self.context.save()
            return parent
        }
    }

    func delete() async throws {
        try await context.perform {
            let request = ParentEntity.fetchRequest()
            let entities = try self.context.fetch(request)

            for entity in entities {
                self.context.delete(entity)
            }

            try self.context.save()
        }
    }

    // MARK: - Mapping

    private func mapToEntity(_ parent: Parent, entity: ParentEntity) {
        entity.id = parent.id
        entity.name = parent.name
        entity.email = parent.email
        entity.createdDate = parent.createdDate
        entity.lastLoginDate = parent.lastLoginDate

        if let preferencesData = try? JSONEncoder().encode(parent.notificationPreferences) {
            entity.notificationPreferencesData = preferencesData
        }
    }

    private func mapFromEntity(_ entity: ParentEntity) -> Parent {
        var preferences = ParentNotificationPreferences()
        if let data = entity.notificationPreferencesData,
           let decoded = try? JSONDecoder().decode(ParentNotificationPreferences.self, from: data) {
            preferences = decoded
        }

        return Parent(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            email: entity.email ?? "",
            createdDate: entity.createdDate ?? Date(),
            lastLoginDate: entity.lastLoginDate,
            notificationPreferences: preferences
        )
    }
}
