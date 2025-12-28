//
//  MockActivityService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of ActivityService for testing and previews.
class MockActivityService: ActivityServiceProtocol {

    // MARK: - Mock Data

    var mockActivities: [Activity] = []
    var mockError: Error?

    var logActivityCallCount = 0
    var fetchTodayCallCount = 0
    var deleteCallCount = 0

    // MARK: - ActivityServiceProtocol

    func logActivity(category: Category, duration: TimeInterval, child: Child, isComplete: Bool = true) async throws -> Activity {
        logActivityCallCount += 1

        if let error = mockError {
            throw error
        }

        let activity = Activity(
            categoryId: category.id,
            childId: child.id,
            startTime: Date().addingTimeInterval(-duration),
            endTime: Date(),
            isComplete: isComplete
        )

        mockActivities.append(activity)
        return activity
    }

    func fetchTodayActivities(for child: Child) async throws -> [Activity] {
        fetchTodayCallCount += 1

        if let error = mockError {
            throw error
        }

        return mockActivities.filter { $0.childId == child.id }
    }

    func fetchActivities(for child: Child, dateRange: DateInterval) async throws -> [Activity] {
        if let error = mockError {
            throw error
        }

        return mockActivities.filter { activity in
            activity.childId == child.id &&
            activity.startTime >= dateRange.start &&
            activity.endTime <= dateRange.end
        }
    }

    func updateActivity(_ activity: Activity) async throws -> Activity {
        if let error = mockError {
            throw error
        }

        if let index = mockActivities.firstIndex(where: { $0.id == activity.id }) {
            mockActivities[index] = activity
        }

        return activity
    }

    func deleteActivity(_ activityId: UUID) async throws {
        deleteCallCount += 1

        if let error = mockError {
            throw error
        }

        mockActivities.removeAll { $0.id == activityId }
    }

    func calculateDailyAggregates(for child: Child, date: Date) async throws -> [CategoryAggregate] {
        if let error = mockError {
            throw error
        }

        // Return empty aggregates for mock
        return []
    }

    // MARK: - Helper Methods

    func reset() {
        mockActivities = []
        mockError = nil
        logActivityCallCount = 0
        fetchTodayCallCount = 0
        deleteCallCount = 0
    }

    func addMockActivities(_ count: Int, for childId: UUID, categoryId: UUID) {
        for i in 0..<count {
            let activity = Activity(
                categoryId: categoryId,
                childId: childId,
                startTime: Date().addingTimeInterval(TimeInterval(-3600 * (i + 1))),
                endTime: Date().addingTimeInterval(TimeInterval(-3600 * i - 1800))
            )
            mockActivities.append(activity)
        }
    }
}
