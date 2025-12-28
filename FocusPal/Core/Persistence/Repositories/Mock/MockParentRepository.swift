//
//  MockParentRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of ParentRepository for testing and previews.
class MockParentRepository: ParentRepositoryProtocol {

    // MARK: - Mock Data

    var mockParent: Parent?
    var mockError: Error?

    // MARK: - ParentRepositoryProtocol

    func create(_ parent: Parent) async throws -> Parent {
        if let error = mockError { throw error }
        mockParent = parent
        return parent
    }

    func fetch() async throws -> Parent? {
        if let error = mockError { throw error }
        return mockParent
    }

    func update(_ parent: Parent) async throws -> Parent {
        if let error = mockError { throw error }
        guard mockParent != nil else {
            throw RepositoryError.entityNotFound
        }
        mockParent = parent
        return parent
    }

    func delete() async throws {
        if let error = mockError { throw error }
        mockParent = nil
    }

    // MARK: - Helper Methods

    func reset() {
        mockParent = nil
        mockError = nil
    }

    static func withSampleData() -> MockParentRepository {
        let repo = MockParentRepository()
        repo.mockParent = Parent(
            name: "Jane Doe",
            email: "jane@example.com",
            notificationPreferences: ParentNotificationPreferences(
                weeklyEmailEnabled: true,
                weeklyEmailDay: 1,
                weeklyEmailTime: 9,
                achievementAlertsEnabled: true
            )
        )
        return repo
    }
}
