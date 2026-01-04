//
//  CategoryData.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Codable wrapper for persisting Category to UserDefaults.
/// Used for category storage and Siri integration.
struct CategoryData: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let isSystem: Bool
    let recommendedDuration: TimeInterval
    let categoryType: String?       // Optional for migration from older versions
    let pointsMultiplier: Double?   // Optional for migration from older versions

    /// Storage key for global categories in UserDefaults
    static let storageKey = "globalCategories"

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconName = category.iconName
        self.colorHex = category.colorHex
        self.isActive = category.isActive
        self.sortOrder = category.sortOrder
        self.isSystem = category.isSystem
        self.recommendedDuration = category.recommendedDuration
        self.categoryType = category.categoryType.rawValue
        self.pointsMultiplier = category.pointsMultiplier
    }

    /// Placeholder child ID for global categories
    static let globalChildId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    func toCategory(childId: UUID) -> Category {
        Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: sortOrder,
            isSystem: isSystem,
            childId: childId,
            recommendedDuration: recommendedDuration,
            categoryType: CategoryType(rawValue: categoryType ?? "task") ?? .task,
            pointsMultiplier: pointsMultiplier ?? 1.0
        )
    }

    /// Convenience method that uses the global child ID
    func toCategory() -> Category {
        toCategory(childId: Self.globalChildId)
    }

    // MARK: - Static Helpers

    /// Load all categories from UserDefaults
    static func loadAll(for childId: UUID) -> [Category] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            return decoded.map { $0.toCategory(childId: childId) }
        }
        return Category.defaultCategories(for: childId)
    }

    /// Load active categories from UserDefaults
    static func loadActive(for childId: UUID) -> [Category] {
        return loadAll(for: childId).filter { $0.isActive }
    }

    /// Load active task categories (not rewards) from UserDefaults
    static func loadActiveTasks(for childId: UUID) -> [Category] {
        return loadActive(for: childId).filter { $0.categoryType == .task }
    }
}
