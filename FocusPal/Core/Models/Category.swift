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
    var recommendedDuration: TimeInterval  // Duration in seconds

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String,
        isActive: Bool = true,
        sortOrder: Int = 0,
        isSystem: Bool = false,
        parentCategoryId: UUID? = nil,
        childId: UUID,
        recommendedDuration: TimeInterval = 25 * 60  // Default 25 minutes
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
        self.recommendedDuration = recommendedDuration
    }

    /// Duration formatted as minutes
    var durationMinutes: Int {
        Int(recommendedDuration / 60)
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
                childId: childId,
                recommendedDuration: 25 * 60  // 25 minutes
            ),
            Category(
                name: "Reading",
                iconName: "text.book.closed.fill",
                colorHex: "#7B68EE",
                sortOrder: 1,
                isSystem: true,
                childId: childId,
                recommendedDuration: 30 * 60  // 30 minutes
            ),
            Category(
                name: "Screen Time",
                iconName: "tv.fill",
                colorHex: "#FF6B6B",
                sortOrder: 2,
                isSystem: true,
                childId: childId,
                recommendedDuration: 45 * 60  // 45 minutes
            ),
            Category(
                name: "Playing",
                iconName: "gamecontroller.fill",
                colorHex: "#4ECDC4",
                sortOrder: 3,
                isSystem: true,
                childId: childId,
                recommendedDuration: 60 * 60  // 60 minutes
            ),
            Category(
                name: "Sports",
                iconName: "figure.run",
                colorHex: "#45B7D1",
                sortOrder: 4,
                isSystem: true,
                childId: childId,
                recommendedDuration: 45 * 60  // 45 minutes
            ),
            Category(
                name: "Music",
                iconName: "music.note",
                colorHex: "#F7DC6F",
                sortOrder: 5,
                isSystem: true,
                childId: childId,
                recommendedDuration: 30 * 60  // 30 minutes
            )
        ]
    }

    /// Available icons for categories
    static let availableIcons: [String] = [
        "book.fill",
        "text.book.closed.fill",
        "tv.fill",
        "gamecontroller.fill",
        "figure.run",
        "music.note",
        "pencil",
        "paintbrush.fill",
        "brain.head.profile",
        "puzzlepiece.fill",
        "building.columns.fill",
        "globe",
        "star.fill",
        "heart.fill",
        "leaf.fill",
        "cup.and.saucer.fill"
    ]

    /// Available colors for categories
    static let availableColors: [String] = [
        "#4A90D9",  // Blue
        "#7B68EE",  // Purple
        "#FF6B6B",  // Red
        "#4ECDC4",  // Teal
        "#45B7D1",  // Light Blue
        "#F7DC6F",  // Yellow
        "#82E0AA",  // Green
        "#F8B500",  // Orange
        "#E74C3C",  // Dark Red
        "#9B59B6",  // Violet
        "#1ABC9C",  // Turquoise
        "#34495E"   // Dark Gray
    ]
}
