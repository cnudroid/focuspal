//
//  AchievementEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Extension to convert between AchievementEntity (Core Data) and Achievement (Domain Model)
extension AchievementEntity {
    /// Creates a domain Achievement model from Core Data entity
    func toDomainModel() -> Achievement? {
        guard let id = id,
              let achievementTypeId = achievementTypeId,
              let child = child,
              let childId = child.id else {
            return nil
        }

        return Achievement(
            id: id,
            achievementTypeId: achievementTypeId,
            childId: childId,
            unlockedDate: unlockedDate,
            progress: Int(progress),
            targetValue: Int(targetValue)
        )
    }

    /// Updates entity from domain model
    func update(from model: Achievement) {
        self.id = model.id
        self.achievementTypeId = model.achievementTypeId
        self.unlockedDate = model.unlockedDate
        self.progress = Int32(model.progress)
        self.targetValue = Int32(model.targetValue)
    }
}

extension Achievement {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext, child: ChildEntity) -> AchievementEntity {
        let entity = AchievementEntity(context: context)
        entity.update(from: self)
        entity.child = child
        return entity
    }
}
