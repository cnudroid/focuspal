//
//  ActivityService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Concrete implementation of the activity service.
/// Manages activity logging, retrieval, and aggregation.
class ActivityService: ActivityServiceProtocol {

    // MARK: - Properties

    private let repository: ActivityRepositoryProtocol

    // MARK: - Initialization

    init(repository: ActivityRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - ActivityServiceProtocol

    func logActivity(category: Category, duration: TimeInterval, child: Child) async throws -> Activity {
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-duration)

        let activity = Activity(
            categoryId: category.id,
            childId: child.id,
            startTime: startTime,
            endTime: endTime,
            isManualEntry: false
        )

        return try await repository.create(activity)
    }

    func fetchTodayActivities(for child: Child) async throws -> [Activity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let dateRange = DateInterval(start: startOfDay, end: endOfDay)
        return try await repository.fetch(for: child.id, dateRange: dateRange)
    }

    func fetchActivities(for child: Child, dateRange: DateInterval) async throws -> [Activity] {
        return try await repository.fetch(for: child.id, dateRange: dateRange)
    }

    func updateActivity(_ activity: Activity) async throws -> Activity {
        return try await repository.update(activity)
    }

    func deleteActivity(_ activityId: UUID) async throws {
        try await repository.delete(activityId)
    }

    func calculateDailyAggregates(for child: Child, date: Date) async throws -> [CategoryAggregate] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let dateRange = DateInterval(start: startOfDay, end: endOfDay)
        let activities = try await repository.fetch(for: child.id, dateRange: dateRange)

        // Group activities by category
        var categoryMap: [UUID: (category: Category?, activities: [Activity])] = [:]

        for activity in activities {
            if categoryMap[activity.categoryId] == nil {
                categoryMap[activity.categoryId] = (nil, [])
            }
            categoryMap[activity.categoryId]?.activities.append(activity)
        }

        // Calculate aggregates
        // Note: In a real implementation, we would fetch category details
        var aggregates: [CategoryAggregate] = []

        for (categoryId, data) in categoryMap {
            let totalSeconds = data.activities.reduce(0) { $0 + Int($1.duration) }
            let totalMinutes = totalSeconds / 60

            // Placeholder category - in real implementation, fetch from CategoryService
            let placeholderCategory = Category(
                id: categoryId,
                name: "Category",
                iconName: "circle.fill",
                colorHex: "#888888",
                childId: child.id
            )

            let aggregate = CategoryAggregate(
                category: placeholderCategory,
                totalMinutes: totalMinutes,
                activityCount: data.activities.count
            )
            aggregates.append(aggregate)
        }

        return aggregates.sorted { $0.totalMinutes > $1.totalMinutes }
    }
}
