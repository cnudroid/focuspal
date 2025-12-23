//
//  CategoryEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Extension to convert between CategoryEntity (Core Data) and Category (Domain Model)
extension CategoryEntity {
    /// Creates a domain Category model from Core Data entity
    func toDomainModel() -> Category? {
        guard let id = id,
              let name = name,
              let iconName = iconName,
              let colorHex = colorHex,
              let child = child,
              let childId = child.id else {
            return nil
        }

        return Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: Int(sortOrder),
            isSystem: isSystem,
            parentCategoryId: parentCategory?.id,
            childId: childId,
            recommendedDuration: recommendedDuration
        )
    }

    /// Updates entity from domain model
    func update(from model: Category) {
        self.id = model.id
        self.name = model.name
        self.iconName = model.iconName
        self.colorHex = model.colorHex
        self.isActive = model.isActive
        self.sortOrder = Int16(model.sortOrder)
        self.isSystem = model.isSystem
        self.recommendedDuration = model.recommendedDuration
    }
}

extension Category {
    /// Creates a new Core Data entity from domain model
    func toEntity(context: NSManagedObjectContext, child: ChildEntity, parentCategory: CategoryEntity? = nil) -> CategoryEntity {
        let entity = CategoryEntity(context: context)
        entity.update(from: self)
        entity.child = child
        entity.parentCategory = parentCategory
        return entity
    }
}
