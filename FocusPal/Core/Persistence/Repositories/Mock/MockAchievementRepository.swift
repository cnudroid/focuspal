//
//  MockAchievementRepository.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Mock implementation of AchievementRepositoryProtocol for testing.
/// Stores achievements in memory using a dictionary.
class MockAchievementRepository: AchievementRepositoryProtocol {

    // MARK: - Properties

    private var achievements: [UUID: Achievement] = [:]
    private let queue = DispatchQueue(label: "com.focuspal.mockachievementrepository")
    var achievementsToReturn: [Achievement] = []

    // MARK: - AchievementRepositoryProtocol

    func create(_ achievement: Achievement) async throws -> Achievement {
        return await withCheckedContinuation { continuation in
            queue.async {
                self.achievements[achievement.id] = achievement
                continuation.resume(returning: achievement)
            }
        }
    }

    func fetchAll(for childId: UUID) async throws -> [Achievement] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.achievements.values.filter { $0.childId == childId }
                continuation.resume(returning: Array(filtered))
            }
        }
    }

    func fetch(for childId: UUID, achievementTypeId: String) async throws -> Achievement? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let found = self.achievements.values.first {
                    $0.childId == childId && $0.achievementTypeId == achievementTypeId
                }
                continuation.resume(returning: found)
            }
        }
    }

    func update(_ achievement: Achievement) async throws -> Achievement {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard self.achievements[achievement.id] != nil else {
                    continuation.resume(throwing: MockRepositoryError.notFound)
                    return
                }
                self.achievements[achievement.id] = achievement
                continuation.resume(returning: achievement)
            }
        }
    }

    func delete(_ achievementId: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async {
                self.achievements.removeValue(forKey: achievementId)
                continuation.resume()
            }
        }
    }

    func fetchUnlocked(for childId: UUID) async throws -> [Achievement] {
        return await withCheckedContinuation { continuation in
            queue.async {
                // If achievementsToReturn is set, use that; otherwise use achievements dict
                if !self.achievementsToReturn.isEmpty {
                    let filtered = self.achievementsToReturn.filter {
                        $0.childId == childId && $0.isUnlocked
                    }
                    continuation.resume(returning: filtered)
                } else {
                    let unlocked = self.achievements.values.filter {
                        $0.childId == childId && $0.isUnlocked
                    }
                    continuation.resume(returning: Array(unlocked))
                }
            }
        }
    }

    func fetchLocked(for childId: UUID) async throws -> [Achievement] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let locked = self.achievements.values.filter {
                    $0.childId == childId && !$0.isUnlocked
                }
                continuation.resume(returning: Array(locked))
            }
        }
    }

    // MARK: - Test Helpers

    func reset() {
        queue.sync {
            achievements.removeAll()
        }
    }
}

/// Errors specific to mock repository operations
enum MockRepositoryError: Error {
    case notFound
    case alreadyExists
}
