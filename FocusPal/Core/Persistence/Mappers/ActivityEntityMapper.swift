//
//  ActivityEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Extension to convert between ActivityEntity (Core Data) and Activity (Domain Model)
extension ActivityEntity {
    /// Creates a domain Activity model from Core Data entity
    func toDomainModel() -> Activity? {
        guard let id = id,
              let startTime = startTime,
              let endTime = endTime,
              let createdDate = createdDate,
              let syncStatusRaw = syncStatus,
              let category = category,
              let categoryId = category.id,
              let child = child,
              let childId = child.id else {
            return nil
        }

        let moodValue = Mood(rawValue: Int(mood)) ?? .none
        let syncStatusValue = SyncStatus(rawValue: syncStatusRaw) ?? .pending

        return Activity(
            id: id,
            categoryId: categoryId,
            childId: childId,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            mood: moodValue,
            isManualEntry: isManualEntry,
            createdDate: createdDate,
            syncStatus: syncStatusValue
        )
    }

    /// Updates entity from domain model
    func update(from model: Activity) {
        self.id = model.id
        self.startTime = model.startTime
        self.endTime = model.endTime
        self.notes = model.notes
        self.mood = Int16(model.mood.rawValue)
        self.isManualEntry = model.isManualEntry
        self.createdDate = model.createdDate
        self.syncStatus = model.syncStatus.rawValue
    }
}

extension Activity {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext, category: CategoryEntity, child: ChildEntity) -> ActivityEntity {
        let entity = ActivityEntity(context: context)
        entity.update(from: self)
        entity.category = category
        entity.child = child
        return entity
    }
}
