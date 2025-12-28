//
//  CoreDataPointsRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import CoreData

/// Core Data implementation of the points repository.
class CoreDataPointsRepository: PointsRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - PointsRepositoryProtocol - ChildPoints

    func saveChildPoints(_ childPoints: ChildPoints) async throws -> ChildPoints {
        return try await context.perform {
            // Try to fetch existing entity using the deterministic ID
            let request = ChildPointsEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", childPoints.id as CVarArg)
            request.fetchLimit = 1

            let entity: ChildPointsEntity
            if let existingEntity = try self.context.fetch(request).first {
                // Update existing entity
                entity = existingEntity
            } else {
                // Create new entity
                entity = ChildPointsEntity(context: self.context)
            }

            // Update entity values
            entity.update(from: childPoints)

            // Link to child entity if available
            let childRequest = ChildEntity.fetchRequest()
            childRequest.predicate = NSPredicate(format: "id == %@", childPoints.childId as CVarArg)
            childRequest.fetchLimit = 1
            if let childEntity = try? self.context.fetch(childRequest).first {
                entity.child = childEntity
            }

            try self.context.save()
            return childPoints
        }
    }

    func fetchChildPoints(for childId: UUID, date: Date) async throws -> ChildPoints? {
        return try await context.perform {
            // Normalize date to start of day
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let request = ChildPointsEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "childId == %@ AND date >= %@ AND date < %@",
                childId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }

    func fetchChildPoints(for childId: UUID, dateRange: DateInterval) async throws -> [ChildPoints] {
        return try await context.perform {
            let request = ChildPointsEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "childId == %@ AND date >= %@ AND date < %@",
                childId as CVarArg,
                dateRange.start as CVarArg,
                dateRange.end as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }

    // MARK: - PointsRepositoryProtocol - Transactions

    func createTransaction(_ transaction: PointsTransaction) async throws -> PointsTransaction {
        return try await context.perform {
            let entity = PointsTransactionEntity(context: self.context)
            entity.update(from: transaction)

            // Link to child entity if available
            let childRequest = ChildEntity.fetchRequest()
            childRequest.predicate = NSPredicate(format: "id == %@", transaction.childId as CVarArg)
            childRequest.fetchLimit = 1
            if let childEntity = try? self.context.fetch(childRequest).first {
                entity.child = childEntity
            }

            try self.context.save()
            return transaction
        }
    }

    func fetchTransactions(for childId: UUID, limit: Int) async throws -> [PointsTransaction] {
        return try await context.perform {
            let request = PointsTransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "childId == %@", childId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = limit

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }

    func fetchTransactions(for childId: UUID, dateRange: DateInterval) async throws -> [PointsTransaction] {
        return try await context.perform {
            let request = PointsTransactionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "childId == %@ AND timestamp >= %@ AND timestamp < %@",
                childId as CVarArg,
                dateRange.start as CVarArg,
                dateRange.end as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { $0.toDomainModel() }
        }
    }
}
