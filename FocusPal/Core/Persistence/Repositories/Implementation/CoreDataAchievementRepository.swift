//
//  CoreDataAchievementRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the achievement repository.
class CoreDataAchievementRepository: AchievementRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - AchievementRepositoryProtocol

    func create(_ achievement: Achievement) async throws -> Achievement {
        return try await context.perform {
            let entity = AchievementEntity(context: self.context)
            try self.mapToEntity(achievement, entity: entity)
            try self.context.save()
            return achievement
        }
    }

    func fetchAll(for childId: UUID) async throws -> [Achievement] {
        return try await context.perform {
            let request = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(format: "child.id == %@", childId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "achievementTypeId", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetch(for childId: UUID, achievementTypeId: String) async throws -> Achievement? {
        return try await context.perform {
            let request = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND achievementTypeId == %@",
                childId as CVarArg,
                achievementTypeId
            )
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first.map { self.mapFromEntity($0) }
        }
    }

    func update(_ achievement: Achievement) async throws -> Achievement {
        return try await context.perform {
            let request = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", achievement.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            try self.mapToEntity(achievement, entity: entity)
            try self.context.save()
            return achievement
        }
    }

    func delete(_ achievementId: UUID) async throws {
        try await context.perform {
            let request = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", achievementId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.context.delete(entity)
            try self.context.save()
        }
    }

    func fetchUnlocked(for childId: UUID) async throws -> [Achievement] {
        return try await context.perform {
            let request = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND unlockedDate != nil",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "unlockedDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    func fetchLocked(for childId: UUID) async throws -> [Achievement] {
        return try await context.perform {
            let request = AchievementEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND unlockedDate == nil",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "achievementTypeId", ascending: true)]

            let entities = try self.context.fetch(request)
            return entities.map { self.mapFromEntity($0) }
        }
    }

    // MARK: - Mapping

    private func mapToEntity(_ achievement: Achievement, entity: AchievementEntity) throws {
        entity.id = achievement.id
        entity.achievementTypeId = achievement.achievementTypeId
        entity.progress = Int32(achievement.progress)
        entity.targetValue = Int32(achievement.targetValue)
        entity.unlockedDate = achievement.unlockedDate

        // Link to child entity
        let childRequest = ChildEntity.fetchRequest()
        childRequest.predicate = NSPredicate(format: "id == %@", achievement.childId as CVarArg)
        childRequest.fetchLimit = 1

        if let childEntity = try context.fetch(childRequest).first {
            entity.child = childEntity
        }
    }

    private func mapFromEntity(_ entity: AchievementEntity) -> Achievement {
        Achievement(
            id: entity.id ?? UUID(),
            achievementTypeId: entity.achievementTypeId ?? "",
            childId: entity.child?.id ?? UUID(),
            unlockedDate: entity.unlockedDate,
            progress: Int(entity.progress),
            targetValue: Int(entity.targetValue)
        )
    }
}
