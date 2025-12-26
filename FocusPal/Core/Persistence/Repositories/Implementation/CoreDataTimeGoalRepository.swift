//
//  CoreDataTimeGoalRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the time goal repository.
class CoreDataTimeGoalRepository: TimeGoalRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - TimeGoalRepositoryProtocol

    func create(_ timeGoal: TimeGoal) async throws -> TimeGoal {
        return try await context.perform {
            let entity = TimeGoalEntity(context: self.context)
            try self.mapToEntity(timeGoal, entity: entity)
            try self.context.save()
            return timeGoal
        }
    }

    func fetchAll(for childId: UUID) async throws -> [TimeGoal] {
        return try await context.perform {
            let request = TimeGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "child.id == %@", childId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetch(for childId: UUID, categoryId: UUID) async throws -> TimeGoal? {
        return try await context.perform {
            let request = TimeGoalEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND category.id == %@",
                childId as CVarArg,
                categoryId as CVarArg
            )
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func fetch(by id: UUID) async throws -> TimeGoal? {
        return try await context.perform {
            let request = TimeGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func update(_ timeGoal: TimeGoal) async throws -> TimeGoal {
        return try await context.perform {
            let request = TimeGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", timeGoal.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            try self.mapToEntity(timeGoal, entity: entity)
            try self.context.save()
            return timeGoal
        }
    }

    func delete(_ timeGoalId: UUID) async throws {
        try await context.perform {
            let request = TimeGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", timeGoalId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.context.delete(entity)
            try self.context.save()
        }
    }

    func fetchActive(for childId: UUID) async throws -> [TimeGoal] {
        return try await context.perform {
            let request = TimeGoalEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND isActive == YES",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    // MARK: - Mapping

    private func mapToEntity(_ timeGoal: TimeGoal, entity: TimeGoalEntity) throws {
        entity.id = timeGoal.id
        entity.recommendedMinutes = Int32(timeGoal.recommendedMinutes)
        entity.warningThreshold = Int16(timeGoal.warningThreshold)
        entity.isActive = timeGoal.isActive
        entity.createdDate = timeGoal.createdDate

        // Link to child entity
        let childRequest = ChildEntity.fetchRequest()
        childRequest.predicate = NSPredicate(format: "id == %@", timeGoal.childId as CVarArg)
        childRequest.fetchLimit = 1

        if let childEntity = try context.fetch(childRequest).first {
            entity.child = childEntity
        }

        // Link to category entity
        let categoryRequest = CategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", timeGoal.categoryId as CVarArg)
        categoryRequest.fetchLimit = 1

        if let categoryEntity = try context.fetch(categoryRequest).first {
            entity.category = categoryEntity
        }
    }

    private func mapFromEntity(_ entity: TimeGoalEntity) -> TimeGoal {
        TimeGoal(
            id: entity.id ?? UUID(),
            categoryId: entity.category?.id ?? UUID(),
            childId: entity.child?.id ?? UUID(),
            recommendedMinutes: Int(entity.recommendedMinutes),
            warningThreshold: Int(entity.warningThreshold),
            isActive: entity.isActive,
            createdDate: entity.createdDate ?? Date()
        )
    }
}
