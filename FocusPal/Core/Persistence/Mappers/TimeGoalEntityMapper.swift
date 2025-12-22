//
//  TimeGoalEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Extension to convert between TimeGoalEntity (Core Data) and TimeGoal (Domain Model)
extension TimeGoalEntity {
    /// Creates a domain TimeGoal model from Core Data entity
    func toDomainModel() -> TimeGoal? {
        guard let id = id,
              let createdDate = createdDate,
              let category = category,
              let categoryId = category.id,
              let child = child,
              let childId = child.id else {
            return nil
        }

        return TimeGoal(
            id: id,
            categoryId: categoryId,
            childId: childId,
            recommendedMinutes: Int(recommendedMinutes),
            warningThreshold: Int(warningThreshold),
            isActive: isActive,
            createdDate: createdDate
        )
    }

    /// Updates entity from domain model
    func update(from model: TimeGoal) {
        self.id = model.id
        self.recommendedMinutes = Int32(model.recommendedMinutes)
        self.warningThreshold = Int16(model.warningThreshold)
        self.isActive = model.isActive
        self.createdDate = model.createdDate
    }
}

extension TimeGoal {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext, category: CategoryEntity, child: ChildEntity) -> TimeGoalEntity {
        let entity = TimeGoalEntity(context: context)
        entity.update(from: self)
        entity.category = category
        entity.child = child
        return entity
    }
}
