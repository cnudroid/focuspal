//
//  ChildEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Extension to convert between ChildEntity (Core Data) and Child (Domain Model)
extension ChildEntity {
    /// Creates a domain Child model from Core Data entity
    func toDomainModel() -> Child? {
        guard let id = id,
              let name = name,
              let avatarId = avatarId,
              let themeColor = themeColor,
              let createdDate = createdDate else {
            return nil
        }

        var preferences = ChildPreferences()
        if let preferencesData = preferencesData {
            preferences = (try? JSONDecoder().decode(ChildPreferences.self, from: preferencesData)) ?? ChildPreferences()
        }

        return Child(
            id: id,
            name: name,
            age: Int(age),
            avatarId: avatarId,
            themeColor: themeColor,
            preferences: preferences,
            createdDate: createdDate,
            lastActiveDate: lastActiveDate,
            isActive: isActive
        )
    }

    /// Updates entity from domain model
    func update(from model: Child) {
        self.id = model.id
        self.name = model.name
        self.age = Int16(model.age)
        self.avatarId = model.avatarId
        self.themeColor = model.themeColor
        self.preferencesData = try? JSONEncoder().encode(model.preferences)
        self.createdDate = model.createdDate
        self.lastActiveDate = model.lastActiveDate
        self.isActive = model.isActive
    }
}

extension Child {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext) -> ChildEntity {
        let entity = ChildEntity(context: context)
        entity.update(from: self)
        return entity
    }
}
