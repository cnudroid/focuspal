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
            print("✅ Activity SAVED to CoreData:")
            print("   ID: \(activity.id)")
            print("   ChildID: \(activity.childId)")
            print("   CategoryID: \(activity.categoryId)")
            print("   Duration: \(activity.durationMinutes) min")
            return activity
        }
    }

    func fetch(for childId: UUID, dateRange: DateInterval) async throws -> [Activity] {
        return try await context.perform {
            let request = ActivityEntity.fetchRequest()
            // Use direct childId attribute instead of relationship
            request.predicate = NSPredicate(
                format: "childId == %@ AND startTime >= %@ AND startTime <= %@",
                childId as CVarArg,
                dateRange.start as CVarArg,
                dateRange.end as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
            request.fetchBatchSize = 20

            let entities = try self.context.fetch(request)
            print("🔍 FETCH activities for childId: \(childId)")
            print("   Date range: \(dateRange.start) to \(dateRange.end)")
            print("   Found: \(entities.count) activities")
            for entity in entities {
                print("   - \(entity.id?.uuidString ?? "no id"), childId: \(entity.childId?.uuidString ?? "nil")")
            }
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
            // Use direct attributes instead of relationships
            request.predicate = NSPredicate(
                format: "childId == %@ AND categoryId == %@",
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

        // Store IDs directly as attributes (more reliable than relationships)
        entity.childId = activity.childId
        entity.categoryId = activity.categoryId

        // Also try to link relationships if entities exist
        let childRequest = ChildEntity.fetchRequest()
        childRequest.predicate = NSPredicate(format: "id == %@", activity.childId as CVarArg)
        childRequest.fetchLimit = 1
        if let childEntity = try? context.fetch(childRequest).first {
            entity.child = childEntity
        }

        let categoryRequest = CategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", activity.categoryId as CVarArg)
        categoryRequest.fetchLimit = 1
        if let categoryEntity = try? context.fetch(categoryRequest).first {
            entity.category = categoryEntity
        }
    }

    private func mapFromEntity(_ entity: ActivityEntity) -> Activity {
        Activity(
            id: entity.id ?? UUID(),
            // Prefer direct attributes, fall back to relationships
            categoryId: entity.categoryId ?? entity.category?.id ?? UUID(),
            childId: entity.childId ?? entity.child?.id ?? UUID(),
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
