//
//  MockChildRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of ChildRepository for testing and previews.
class MockChildRepository: ChildRepositoryProtocol {

    // MARK: - Mock Data

    var mockChildren: [Child] = []
    var mockError: Error?
    var activeChildId: UUID?

    // MARK: - ChildRepositoryProtocol

    func create(_ child: Child) async throws -> Child {
        if let error = mockError { throw error }
        mockChildren.append(child)
        return child
    }

    func fetchAll() async throws -> [Child] {
        if let error = mockError { throw error }
        return mockChildren
    }

    func fetch(by id: UUID) async throws -> Child? {
        if let error = mockError { throw error }
        return mockChildren.first { $0.id == id }
    }

    func update(_ child: Child) async throws -> Child {
        if let error = mockError { throw error }
        if let index = mockChildren.firstIndex(where: { $0.id == child.id }) {
            mockChildren[index] = child
        }
        return child
    }

    func delete(_ childId: UUID) async throws {
        if let error = mockError { throw error }
        mockChildren.removeAll { $0.id == childId }
    }

    func fetchActiveChild() async throws -> Child? {
        if let error = mockError { throw error }
        if let activeId = activeChildId {
            return mockChildren.first { $0.id == activeId }
        }
        return mockChildren.first { $0.isActive }
    }

    func setActiveChild(_ childId: UUID) async throws {
        if let error = mockError { throw error }
        activeChildId = childId
    }

    // MARK: - Helper Methods

    func reset() {
        mockChildren = []
        mockError = nil
        activeChildId = nil
    }

    static func withSampleData() -> MockChildRepository {
        let repo = MockChildRepository()
        repo.mockChildren = [
            Child(name: "Emma", age: 8, avatarId: "avatar_girl_1", themeColor: "pink"),
            Child(name: "Lucas", age: 10, avatarId: "avatar_boy_1", themeColor: "blue")
        ]
        repo.activeChildId = repo.mockChildren.first?.id
        return repo
    }
}
