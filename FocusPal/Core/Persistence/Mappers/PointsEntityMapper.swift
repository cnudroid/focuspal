//
//  PointsEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

// MARK: - ChildPointsEntity Mapper

/// Extension to convert between ChildPointsEntity (Core Data) and ChildPoints (Domain Model)
extension ChildPointsEntity {
    /// Creates a domain ChildPoints model from Core Data entity
    func toDomainModel() -> ChildPoints? {
        guard let id = id,
              let childId = childId,
              let date = date else {
            return nil
        }

        return ChildPoints(
            id: id,
            childId: childId,
            date: date,
            pointsEarned: Int(pointsEarned),
            pointsDeducted: Int(pointsDeducted),
            bonusPoints: Int(bonusPoints)
        )
    }

    /// Updates entity from domain model
    func update(from model: ChildPoints) {
        self.id = model.id
        self.childId = model.childId
        self.date = model.date
        self.pointsEarned = Int32(model.pointsEarned)
        self.pointsDeducted = Int32(model.pointsDeducted)
        self.bonusPoints = Int32(model.bonusPoints)
    }
}

extension ChildPoints {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext, child: ChildEntity) -> ChildPointsEntity {
        let entity = ChildPointsEntity(context: context)
        entity.update(from: self)
        entity.child = child
        return entity
    }
}

// MARK: - PointsTransactionEntity Mapper

/// Extension to convert between PointsTransactionEntity (Core Data) and PointsTransaction (Domain Model)
extension PointsTransactionEntity {
    /// Creates a domain PointsTransaction model from Core Data entity
    func toDomainModel() -> PointsTransaction? {
        guard let id = id,
              let childId = childId,
              let reasonString = reason,
              let reason = PointsReason(rawValue: reasonString),
              let timestamp = timestamp else {
            return nil
        }

        return PointsTransaction(
            id: id,
            childId: childId,
            activityId: activityId,
            amount: Int(amount),
            reason: reason,
            timestamp: timestamp
        )
    }

    /// Updates entity from domain model
    func update(from model: PointsTransaction) {
        self.id = model.id
        self.childId = model.childId
        self.activityId = model.activityId
        self.amount = Int32(model.amount)
        self.reason = model.reason.rawValue
        self.timestamp = model.timestamp
    }
}

extension PointsTransaction {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext, child: ChildEntity) -> PointsTransactionEntity {
        let entity = PointsTransactionEntity(context: context)
        entity.update(from: self)
        entity.child = child
        return entity
    }
}
