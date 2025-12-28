//
//  MockActivityRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of ActivityRepository for testing and previews.
class MockActivityRepository: ActivityRepositoryProtocol {

    // MARK: - Mock Data

    var mockActivities: [Activity] = []
    var mockError: Error?
    var activitiesToReturn: [Activity] = []

    // MARK: - ActivityRepositoryProtocol

    func create(_ activity: Activity) async throws -> Activity {
        if let error = mockError { throw error }
        mockActivities.append(activity)
        return activity
    }

    func fetch(for childId: UUID, dateRange: DateInterval) async throws -> [Activity] {
        if let error = mockError { throw error }
        // If activitiesToReturn is set, use that; otherwise use mockActivities
        let source = activitiesToReturn.isEmpty ? mockActivities : activitiesToReturn
        return source.filter { activity in
            activity.childId == childId &&
            activity.startTime >= dateRange.start &&
            activity.endTime <= dateRange.end
        }
    }

    func fetch(by id: UUID) async throws -> Activity? {
        if let error = mockError { throw error }
        return mockActivities.first { $0.id == id }
    }

    func update(_ activity: Activity) async throws -> Activity {
        if let error = mockError { throw error }
        if let index = mockActivities.firstIndex(where: { $0.id == activity.id }) {
            mockActivities[index] = activity
        }
        return activity
    }

    func delete(_ activityId: UUID) async throws {
        if let error = mockError { throw error }
        mockActivities.removeAll { $0.id == activityId }
    }

    func fetch(for childId: UUID, categoryId: UUID) async throws -> [Activity] {
        if let error = mockError { throw error }
        return mockActivities.filter {
            $0.childId == childId && $0.categoryId == categoryId
        }
    }

    func fetchPendingSync() async throws -> [Activity] {
        if let error = mockError { throw error }
        return mockActivities.filter { $0.syncStatus == .pending }
    }

    func markSynced(_ activityIds: [UUID]) async throws {
        if let error = mockError { throw error }
        for i in mockActivities.indices {
            if activityIds.contains(mockActivities[i].id) {
                var activity = mockActivities[i]
                activity = Activity(
                    id: activity.id,
                    categoryId: activity.categoryId,
                    childId: activity.childId,
                    startTime: activity.startTime,
                    endTime: activity.endTime,
                    notes: activity.notes,
                    mood: activity.mood,
                    isManualEntry: activity.isManualEntry,
                    createdDate: activity.createdDate,
                    syncStatus: .synced
                )
                mockActivities[i] = activity
            }
        }
    }

    // MARK: - Helper Methods

    func reset() {
        mockActivities = []
        mockError = nil
    }
}
