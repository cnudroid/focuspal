//
//  CategoryEntity.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AppIntents
import Foundation

/// AppEntity representing an activity Category for Siri integration.
/// Named SiriCategoryEntity to avoid conflict with Core Data CategoryEntity.
@available(iOS 16.0, *)
struct SiriCategoryEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Activity")
    static var defaultQuery = SiriCategoryEntityQuery()

    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var recommendedDuration: TimeInterval

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(Int(recommendedDuration / 60)) minutes"
        )
    }

    init(id: UUID, name: String, iconName: String, colorHex: String, recommendedDuration: TimeInterval) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.recommendedDuration = recommendedDuration
    }

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconName = category.iconName
        self.colorHex = category.colorHex
        self.recommendedDuration = category.recommendedDuration
    }

    func toCategory(childId: UUID) -> Category {
        Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            childId: childId,
            recommendedDuration: recommendedDuration
        )
    }
}

/// Query for fetching SiriCategoryEntity instances for Siri.
@available(iOS 16.0, *)
struct SiriCategoryEntityQuery: EntityQuery {
    /// Placeholder child ID for loading categories (categories are global, not per-child)
    private static let placeholderChildId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    func entities(for identifiers: [UUID]) async throws -> [SiriCategoryEntity] {
        let categories = CategoryData.loadActive(for: Self.placeholderChildId)
        return categories
            .filter { identifiers.contains($0.id) }
            .map { SiriCategoryEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [SiriCategoryEntity] {
        // Only show task categories (not reward categories like Screen Time)
        let categories = CategoryData.loadActiveTasks(for: Self.placeholderChildId)
        return categories.map { SiriCategoryEntity(from: $0) }
    }
}

/// String-based query for finding categories by name.
@available(iOS 16.0, *)
extension SiriCategoryEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [SiriCategoryEntity] {
        let categories = CategoryData.loadActiveTasks(for: Self.placeholderChildId)
        let lowercasedQuery = string.lowercased()
        return categories
            .filter { $0.name.lowercased().contains(lowercasedQuery) }
            .map { SiriCategoryEntity(from: $0) }
    }
}
