//
//  Category.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Defines whether a category earns points (task) or costs points (reward)
enum CategoryType: String, Codable, CaseIterable {
    case task = "task"       // Earns points on completion
    case reward = "reward"   // Costs points to start

    var displayName: String {
        switch self {
        case .task: return "Task"
        case .reward: return "Reward"
        }
    }

    var description: String {
        switch self {
        case .task: return "Earns points when completed"
        case .reward: return "Costs points to start"
        }
    }

    var iconName: String {
        switch self {
        case .task: return "checkmark.circle.fill"
        case .reward: return "gift.fill"
        }
    }
}

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
    var categoryType: CategoryType         // Task earns points, Reward costs points
    var pointsMultiplier: Double           // Multiplier for points earned/spent (default 1.0)

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
        recommendedDuration: TimeInterval = 25 * 60,  // Default 25 minutes
        categoryType: CategoryType = .task,
        pointsMultiplier: Double = 1.0
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
        self.categoryType = categoryType
        self.pointsMultiplier = pointsMultiplier
    }

    /// Duration formatted as minutes
    var durationMinutes: Int {
        Int(recommendedDuration / 60)
    }
}

/// Predefined system categories
extension Category {
    /// Creates a deterministic UUID from a category name and child ID
    /// This ensures the same category always has the same UUID for a given child
    private static func deterministicId(name: String, childId: UUID) -> UUID {
        // Create a deterministic string and hash it to create a consistent UUID
        let combined = "\(childId.uuidString)-\(name)"
        let hash = combined.utf8.reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            for i in 0..<16 {
                result[i] = result[i] &+ byte &+ UInt8(i)
            }
        }
        // Set version 4 (random) bits to make it a valid UUID format
        var bytes = hash
        bytes[6] = (bytes[6] & 0x0F) | 0x40  // Version 4
        bytes[8] = (bytes[8] & 0x3F) | 0x80  // Variant

        let uuid = NSUUID(uuidBytes: bytes) as UUID
        return uuid
    }

    static func defaultCategories(for childId: UUID?) -> [Category] {
        // Use a fixed UUID for global categories when childId is nil
        let effectiveId = childId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        return [
            Category(
                id: deterministicId(name: "Homework", childId: effectiveId),
                name: "Homework",
                iconName: "book.fill",
                colorHex: "#4A90D9",
                sortOrder: 0,
                isSystem: true,
                childId: effectiveId,
                recommendedDuration: 25 * 60,  // 25 minutes
                categoryType: .task,
                pointsMultiplier: 1.0
            ),
            Category(
                id: deterministicId(name: "Reading", childId: effectiveId),
                name: "Reading",
                iconName: "text.book.closed.fill",
                colorHex: "#7B68EE",
                sortOrder: 1,
                isSystem: true,
                childId: effectiveId,
                recommendedDuration: 30 * 60,  // 30 minutes
                categoryType: .task,
                pointsMultiplier: 1.0
            ),
            Category(
                id: deterministicId(name: "Screen Time", childId: effectiveId),
                name: "Screen Time",
                iconName: "tv.fill",
                colorHex: "#FF6B6B",
                sortOrder: 2,
                isSystem: true,
                childId: effectiveId,
                recommendedDuration: 45 * 60,  // 45 minutes
                categoryType: .reward,
                pointsMultiplier: 1.0
            ),
            Category(
                id: deterministicId(name: "Playing", childId: effectiveId),
                name: "Playing",
                iconName: "gamecontroller.fill",
                colorHex: "#4ECDC4",
                sortOrder: 3,
                isSystem: true,
                childId: effectiveId,
                recommendedDuration: 60 * 60,  // 60 minutes
                categoryType: .reward,
                pointsMultiplier: 1.0
            ),
            Category(
                id: deterministicId(name: "Sports", childId: effectiveId),
                name: "Sports",
                iconName: "figure.run",
                colorHex: "#45B7D1",
                sortOrder: 4,
                isSystem: true,
                childId: effectiveId,
                recommendedDuration: 45 * 60,  // 45 minutes
                categoryType: .task,
                pointsMultiplier: 1.0
            ),
            Category(
                id: deterministicId(name: "Music", childId: effectiveId),
                name: "Music",
                iconName: "music.note",
                colorHex: "#F7DC6F",
                sortOrder: 5,
                isSystem: true,
                childId: effectiveId,
                recommendedDuration: 30 * 60,  // 30 minutes
                categoryType: .task,
                pointsMultiplier: 1.0
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
