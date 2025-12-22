//
//  Category.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Domain model representing an activity category.
/// Categories organize activities and can have parent-child relationships.
struct Category: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var isActive: Bool
    var sortOrder: Int
    var isSystem: Bool
    var parentCategoryId: UUID?
    let childId: UUID

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String,
        isActive: Bool = true,
        sortOrder: Int = 0,
        isSystem: Bool = false,
        parentCategoryId: UUID? = nil,
        childId: UUID
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.isSystem = isSystem
        self.parentCategoryId = parentCategoryId
        self.childId = childId
    }
}

/// Predefined system categories
extension Category {
    static func defaultCategories(for childId: UUID) -> [Category] {
        [
            Category(
                name: "Homework",
                iconName: "book.fill",
                colorHex: "#4A90D9",
                sortOrder: 0,
                isSystem: true,
                childId: childId
            ),
            Category(
                name: "Reading",
                iconName: "text.book.closed.fill",
                colorHex: "#7B68EE",
                sortOrder: 1,
                isSystem: true,
                childId: childId
            ),
            Category(
                name: "Screen Time",
                iconName: "tv.fill",
                colorHex: "#FF6B6B",
                sortOrder: 2,
                isSystem: true,
                childId: childId
            ),
            Category(
                name: "Playing",
                iconName: "gamecontroller.fill",
                colorHex: "#4ECDC4",
                sortOrder: 3,
                isSystem: true,
                childId: childId
            ),
            Category(
                name: "Sports",
                iconName: "figure.run",
                colorHex: "#45B7D1",
                sortOrder: 4,
                isSystem: true,
                childId: childId
            ),
            Category(
                name: "Music",
                iconName: "music.note",
                colorHex: "#F7DC6F",
                sortOrder: 5,
                isSystem: true,
                childId: childId
            )
        ]
    }
}
