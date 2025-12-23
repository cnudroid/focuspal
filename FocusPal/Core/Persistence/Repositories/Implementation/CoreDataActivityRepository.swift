//
//  CoreDataActivityRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the activity repository.
class CoreDataActivityRepository: ActivityRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - ActivityRepositoryProtocol

    func create(_ activity: Activity) async throws -> Activity {
        return try await context.perform {
            let entity = ActivityEntity(context: self.context)
            self.mapToEntity(activity, entity: entity)
            try self.context.save()
            return activity
        }
    }

    func fetch(for childId: UUID, dateRange: DateInterval) async throws -> [Activity] {
        return try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND startTime >= %@ AND startTime <= %@",
                childId as CVarArg,
                dateRange.start as CVarArg,
                dateRange.end as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
            request.fetchBatchSize = 20

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetch(by id: UUID) async throws -> Activity? {
        return try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func update(_ activity: Activity) async throws -> Activity {
        return try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", activity.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.mapToEntity(activity, entity: entity)
            try self.context.save()
            return activity
        }
    }

    func delete(_ activityId: UUID) async throws {
        try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", activityId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.context.delete(entity)
            try self.context.save()
        }
    }

    func fetch(for childId: UUID, categoryId: UUID) async throws -> [Activity] {
        return try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND category.id == %@",
                childId as CVarArg,
                categoryId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetchPendingSync() async throws -> [Activity] {
        return try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func markSynced(_ activityIds: [UUID]) async throws {
        try await context.perform {
            let request = ActivityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", activityIds)

            let entities = try self.context.fetch(request)
            for entity in entities {
                entity.syncStatus = "synced"
            }

            try self.context.save()
        }
    }

    // MARK: - Mapping

    private func mapToEntity(_ activity: Activity, entity: ActivityEntity) {
        entity.id = activity.id
        entity.startTime = activity.startTime
        entity.endTime = activity.endTime
        entity.notes = activity.notes
        entity.mood = Int16(activity.mood.rawValue)
        entity.isManualEntry = activity.isManualEntry
        entity.createdDate = activity.createdDate
        entity.syncStatus = activity.syncStatus.rawValue
    }

    private func mapFromEntity(_ entity: ActivityEntity) -> Activity {
        Activity(
            id: entity.id ?? UUID(),
            categoryId: entity.category?.id ?? UUID(),
            childId: entity.child?.id ?? UUID(),
            startTime: entity.startTime ?? Date(),
            endTime: entity.endTime ?? Date(),
            notes: entity.notes,
            mood: Mood(rawValue: Int(entity.mood)) ?? .none,
            isManualEntry: entity.isManualEntry,
            createdDate: entity.createdDate ?? Date(),
            syncStatus: SyncStatus(rawValue: entity.syncStatus ?? "pending") ?? .pending
        )
    }
}
