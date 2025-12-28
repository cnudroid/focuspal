//
//  CoreDataRewardsRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the rewards repository.
class CoreDataRewardsRepository: RewardsRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - RewardsRepositoryProtocol

    func create(_ reward: WeeklyReward) async throws -> WeeklyReward {
        return try await context.perform {
            // Fetch the child entity
            let childRequest = ChildEntity.fetchRequest()
            childRequest.predicate = NSPredicate(format: "id == %@", reward.childId as CVarArg)
            childRequest.fetchLimit = 1

            guard let childEntity = try self.context.fetch(childRequest).first else {
                throw RepositoryError.entityNotFound
            }

            // Create the reward entity
            let entity = WeeklyRewardEntity(context: self.context)
            entity.update(from: reward)
            entity.child = childEntity

            try self.context.save()
            return reward
        }
    }

    func fetchAll(for childId: UUID) async throws -> [WeeklyReward] {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "child.id == %@", childId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "weekStartDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }

    func fetchRewards(for childId: UUID, from startDate: Date, to endDate: Date) async throws -> [WeeklyReward] {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND weekStartDate >= %@ AND weekStartDate <= %@",
                childId as CVarArg,
                startDate as CVarArg,
                endDate as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "weekStartDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }

    func fetchReward(for childId: UUID, weekStartDate: Date) async throws -> WeeklyReward? {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND weekStartDate == %@",
                childId as CVarArg,
                weekStartDate as CVarArg
            )
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }

    func fetch(by id: UUID) async throws -> WeeklyReward? {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }

    func update(_ reward: WeeklyReward) async throws -> WeeklyReward {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", reward.id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            entity.update(from: reward)
            try self.context.save()
            return reward
        }
    }

    func delete(_ rewardId: UUID) async throws {
        try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", rewardId as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.entityNotFound
            }

            self.context.delete(entity)
            try self.context.save()
        }
    }

    func fetchUnredeemed(for childId: UUID) async throws -> [WeeklyReward] {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND isRedeemed == NO",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "weekStartDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }

    func fetchWithTiers(for childId: UUID) async throws -> [WeeklyReward] {
        return try await context.perform {
            let request = WeeklyRewardEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "child.id == %@ AND tierRaw != nil",
                childId as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "weekStartDate", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }
}
