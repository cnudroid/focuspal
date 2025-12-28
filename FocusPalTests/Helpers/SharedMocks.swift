//
//  SharedMocks.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//
//  Centralized mock implementations for testing.
//  This file provides shared mock classes used across multiple test files.

import Foundation
@testable import FocusPal

// MARK: - Mock PIN Service

/// Shared mock implementation of PINServiceProtocol for testing
class SharedMockPINService: PINServiceProtocol {
    var isPinSetValue = false
    var verifyPinReturnValue = false
    var verifyPinCalled = false
    var savePinCalled = false
    var savedPin: String?
    var savePinCallCount = 0
    var shouldThrowError = false

    func isPinSet() -> Bool {
        return isPinSetValue
    }

    func savePin(pin: String) throws {
        savePinCallCount += 1

        if shouldThrowError {
            throw PINServiceError.keychainError(status: errSecIO)
        }

        // Perform same validation as real service
        guard pin.count == 4 else {
            throw PINServiceError.invalidPinLength
        }

        guard pin.allSatisfy({ $0.isNumber }) else {
            throw PINServiceError.invalidPinFormat
        }

        savePinCalled = true
        savedPin = pin
        isPinSetValue = true
    }

    func verifyPin(pin: String) -> Bool {
        verifyPinCalled = true
        return verifyPinReturnValue || (savedPin == pin)
    }

    func resetPin() {
        isPinSetValue = false
        savedPin = nil
        savePinCalled = false
        savePinCallCount = 0
    }

    func reset() {
        isPinSetValue = false
        savedPin = nil
        savePinCalled = false
        savePinCallCount = 0
        verifyPinCalled = false
        verifyPinReturnValue = false
        shouldThrowError = false
    }
}

// MARK: - Mock Child Repository for Testing

/// Mock child repository specifically for view model tests with call tracking
class TestMockChildRepository: ChildRepositoryProtocol {
    var createdChild: Child?
    var createCallCount = 0
    var shouldThrowError = false
    var mockChildren: [Child] = []
    var activeChildId: UUID?

    func create(_ child: Child) async throws -> Child {
        createCallCount += 1

        if shouldThrowError {
            enum TestError: Error {
                case failed
            }
            throw TestError.failed
        }

        createdChild = child
        mockChildren.append(child)
        return child
    }

    func fetchAll() async throws -> [Child] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return mockChildren
    }

    func fetch(by id: UUID) async throws -> Child? {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return mockChildren.first { $0.id == id }
    }

    func update(_ child: Child) async throws -> Child {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        if let index = mockChildren.firstIndex(where: { $0.id == child.id }) {
            mockChildren[index] = child
        }
        createdChild = child
        return child
    }

    func delete(_ childId: UUID) async throws {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        mockChildren.removeAll { $0.id == childId }
        if createdChild?.id == childId {
            createdChild = nil
        }
    }

    func fetchActiveChild() async throws -> Child? {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        if let activeId = activeChildId {
            return mockChildren.first { $0.id == activeId }
        }
        return mockChildren.first { $0.isActive }
    }

    func setActiveChild(_ childId: UUID) async throws {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        activeChildId = childId
        if var child = mockChildren.first(where: { $0.id == childId }) {
            child.isActive = true
            if let index = mockChildren.firstIndex(where: { $0.id == childId }) {
                mockChildren[index] = child
            }
            createdChild = child
        }
    }

    func reset() {
        mockChildren = []
        createdChild = nil
        createCallCount = 0
        shouldThrowError = false
        activeChildId = nil
    }

    static func withSampleData() -> TestMockChildRepository {
        let repo = TestMockChildRepository()
        repo.mockChildren = [
            Child(name: "Emma", age: 8, avatarId: "avatar_girl_1", themeColor: "pink"),
            Child(name: "Lucas", age: 10, avatarId: "avatar_boy_1", themeColor: "blue")
        ]
        repo.activeChildId = repo.mockChildren.first?.id
        return repo
    }
}

// MARK: - Mock Activity Service for Testing

/// Mock activity service for testing time goal and analytics features
class TestMockActivityService: ActivityServiceProtocol {
    var todayActivities: [Activity] = []
    var aggregates: [CategoryAggregate] = []
    var shouldThrowError = false
    var logActivityCallCount = 0
    var lastLoggedActivity: Activity?

    func logActivity(category: FocusPal.Category, duration: TimeInterval, child: Child, isComplete: Bool = true) async throws -> Activity {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        logActivityCallCount += 1
        let activity = Activity(
            categoryId: category.id,
            childId: child.id,
            startTime: Date().addingTimeInterval(-duration),
            endTime: Date(),
            isComplete: isComplete
        )
        lastLoggedActivity = activity
        todayActivities.append(activity)
        return activity
    }

    func fetchTodayActivities(for child: Child) async throws -> [Activity] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return todayActivities.filter { $0.childId == child.id }
    }

    func fetchActivities(for child: Child, dateRange: DateInterval) async throws -> [Activity] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return todayActivities.filter { activity in
            activity.childId == child.id &&
            dateRange.contains(activity.startTime)
        }
    }

    func updateActivity(_ activity: Activity) async throws -> Activity {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        if let index = todayActivities.firstIndex(where: { $0.id == activity.id }) {
            todayActivities[index] = activity
        }
        return activity
    }

    func deleteActivity(_ activityId: UUID) async throws {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        todayActivities.removeAll { $0.id == activityId }
    }

    func calculateDailyAggregates(for child: Child, date: Date) async throws -> [CategoryAggregate] {
        if shouldThrowError {
            enum TestError: Error { case failed }
            throw TestError.failed
        }
        return aggregates
    }

    func reset() {
        todayActivities = []
        aggregates = []
        shouldThrowError = false
        logActivityCallCount = 0
        lastLoggedActivity = nil
    }
}

// MARK: - Mock Achievement Repository for Testing

/// Mock achievement repository for testing
class TestMockAchievementRepository: AchievementRepositoryProtocol {
    var achievements: [Achievement] = []
    var shouldThrowError = false
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0

    func create(_ achievement: Achievement) async throws -> Achievement {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        createCallCount += 1
        achievements.append(achievement)
        return achievement
    }

    func fetchAll(for childId: UUID) async throws -> [Achievement] {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        return achievements.filter { $0.childId == childId }
    }

    func fetch(for childId: UUID, achievementTypeId: String) async throws -> Achievement? {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        return achievements.first { $0.childId == childId && $0.achievementTypeId == achievementTypeId }
    }

    func update(_ achievement: Achievement) async throws -> Achievement {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        updateCallCount += 1
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index] = achievement
        }
        return achievement
    }

    func delete(_ achievementId: UUID) async throws {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        deleteCallCount += 1
        achievements.removeAll { $0.id == achievementId }
    }

    func fetchUnlocked(for childId: UUID) async throws -> [Achievement] {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        return achievements.filter { $0.childId == childId && $0.isUnlocked }
    }

    func fetchLocked(for childId: UUID) async throws -> [Achievement] {
        if shouldThrowError {
            throw RepositoryError.entityNotFound
        }
        return achievements.filter { $0.childId == childId && !$0.isUnlocked }
    }

    func reset() {
        achievements = []
        shouldThrowError = false
        createCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
    }
}
