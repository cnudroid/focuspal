//
//  CoreDataCategoryRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the category repository.
class CoreDataCategoryRepository: CategoryRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CategoryRepositoryProtocol

    func create(_ category: Category) async throws -> Category {
        return try await context.perform {
            let entity = CategoryEntity(context: self.context)
            self.mapToEntity(category, entity: entity)
            try self.context.save()
            return category
        }
    }

    func fetchAll(for childId: UUID) async throws -> [Category] {
        return try await context.perform {
            let request = CategoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "child.id == %@", childId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetch(by id: UUID) async throws -> Category? {
        return try await context.perform {
            let request = CategoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func update(_ category: Category) async throws -> Category {
        return try await context.perform {
            let request = CategoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.mapToEntity(category, entity: entity)
            try self.context.save()
            return category
        }
    }

    func delete(_ categoryId: UUID) async throws {
        try await context.perform {
            let request = CategoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.context.delete(entity)
            try self.context.save()
        }
    }

    func fetchSystemCategories(for childId: UUID) async throws -> [Category] {
        return try await context.perform {
            let request = CategoryEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND isSystem == YES",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetchCustomCategories(for childId: UUID) async throws -> [Category] {
        return try await context.perform {
            let request = CategoryEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND isSystem == NO",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    // MARK: - Mapping

    private func mapToEntity(_ category: Category, entity: CategoryEntity) {
        entity.id = category.id
        entity.name = category.name
        entity.iconName = category.iconName
        entity.colorHex = category.colorHex
        entity.isActive = category.isActive
        entity.sortOrder = Int16(category.sortOrder)
        entity.isSystem = category.isSystem
        entity.recommendedDuration = category.recommendedDuration
    }

    private func mapFromEntity(_ entity: CategoryEntity) -> Category {
        Category(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            iconName: entity.iconName ?? "folder.fill",
            colorHex: entity.colorHex ?? "#4A90D9",
            isActive: entity.isActive,
            sortOrder: Int(entity.sortOrder),
            isSystem: entity.isSystem,
            parentCategoryId: entity.parentCategory?.id,
            childId: entity.child?.id ?? UUID(),
            recommendedDuration: entity.recommendedDuration
        )
    }
}
