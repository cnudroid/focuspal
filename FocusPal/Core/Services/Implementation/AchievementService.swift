//
//  AchievementService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Concrete implementation of the achievement service.
/// Manages achievement tracking, progress updates, and unlock detection.
class AchievementService: AchievementServiceProtocol {

    // MARK: - Properties

    private let repository: AchievementRepositoryProtocol

    // MARK: - Initialization

    init(repository: AchievementRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - AchievementServiceProtocol

    func initializeAchievements(for child: Child) async throws {
        // Fetch existing achievements to avoid duplicates
        let existing = try await repository.fetchAll(for: child.id)
        let existingTypeIds = Set(existing.map { $0.achievementTypeId })

        // Create missing achievements
        for achievementType in AchievementType.allCases {
            if !existingTypeIds.contains(achievementType.rawValue) {
                let achievement = Achievement(
                    achievementTypeId: achievementType.rawValue,
                    childId: child.id,
                    targetValue: achievementType.targetValue
                )
                _ = try await repository.create(achievement)
            }
        }
    }

    func recordTimerCompletion(for child: Child) async throws -> [Achievement] {
        return try await updateProgress(
            for: child,
            achievementTypeId: AchievementType.firstTimer.rawValue,
            incrementBy: 1
        )
    }

    func recordStreak(days: Int, for child: Child) async throws -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        // Check and update all streak achievements
        let streakTypes: [AchievementType] = [.streak3Day, .streak7Day, .streak30Day]

        for streakType in streakTypes {
            let unlocked = try await updateProgress(
                for: child,
                achievementTypeId: streakType.rawValue,
                setValue: days
            )
            newlyUnlocked.append(contentsOf: unlocked)
        }

        return newlyUnlocked
    }

    func recordCategoryTime(minutes: Int, category: Category, for child: Child) async throws -> [Achievement] {
        // Only track positive minutes
        guard minutes > 0 else { return [] }

        var newlyUnlocked: [Achievement] = []

        // Check if category matches Homework
        if category.name.lowercased().contains("homework") {
            let unlocked = try await updateProgress(
                for: child,
                achievementTypeId: AchievementType.homeworkHero.rawValue,
                incrementBy: minutes
            )
            newlyUnlocked.append(contentsOf: unlocked)
        }

        // Check if category matches Reading
        if category.name.lowercased().contains("reading") {
            let unlocked = try await updateProgress(
                for: child,
                achievementTypeId: AchievementType.readingChampion.rawValue,
                incrementBy: minutes
            )
            newlyUnlocked.append(contentsOf: unlocked)
        }

        return newlyUnlocked
    }

    func recordBalancedWeek(balancedDays: Int, for child: Child) async throws -> [Achievement] {
        return try await updateProgress(
            for: child,
            achievementTypeId: AchievementType.balanceMaster.rawValue,
            setValue: balancedDays
        )
    }

    func recordActivityTime(startTime: Date, for child: Child) async throws -> [Achievement] {
        // Check if activity started before 8 AM
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)

        guard hour < 8 else {
            return []
        }

        return try await updateProgress(
            for: child,
            achievementTypeId: AchievementType.earlyBird.rawValue,
            incrementBy: 1
        )
    }

    func fetchAllAchievements(for child: Child) async throws -> [Achievement] {
        return try await repository.fetchAll(for: child.id)
    }

    func fetchUnlockedAchievements(for child: Child) async throws -> [Achievement] {
        return try await repository.fetchUnlocked(for: child.id)
    }

    func fetchLockedAchievements(for child: Child) async throws -> [Achievement] {
        return try await repository.fetchLocked(for: child.id)
    }

    // MARK: - Private Helper Methods

    /// Update achievement progress by incrementing the current value
    /// - Parameters:
    ///   - child: The child whose achievement to update
    ///   - achievementTypeId: The achievement type identifier
    ///   - incrementBy: Amount to increment progress by
    /// - Returns: Array of newly unlocked achievements (empty if none or already unlocked)
    private func updateProgress(
        for child: Child,
        achievementTypeId: String,
        incrementBy increment: Int
    ) async throws -> [Achievement] {
        guard let achievement = try await repository.fetch(
            for: child.id,
            achievementTypeId: achievementTypeId
        ) else {
            throw AchievementServiceError.achievementNotFound
        }

        // Already unlocked, don't update again
        guard !achievement.isUnlocked else {
            return []
        }

        var updatedAchievement = achievement
        updatedAchievement.progress += increment

        // Check if achievement should be unlocked
        if updatedAchievement.progress >= updatedAchievement.targetValue {
            updatedAchievement.unlockedDate = Date()
        }

        let saved = try await repository.update(updatedAchievement)

        // Return the achievement if it was newly unlocked in this operation
        if saved.isUnlocked && !achievement.isUnlocked {
            return [saved]
        }

        return []
    }

    /// Update achievement progress by setting a specific value
    /// - Parameters:
    ///   - child: The child whose achievement to update
    ///   - achievementTypeId: The achievement type identifier
    ///   - setValue: Value to set progress to
    /// - Returns: Array of newly unlocked achievements (empty if none or already unlocked)
    private func updateProgress(
        for child: Child,
        achievementTypeId: String,
        setValue value: Int
    ) async throws -> [Achievement] {
        guard let achievement = try await repository.fetch(
            for: child.id,
            achievementTypeId: achievementTypeId
        ) else {
            throw AchievementServiceError.achievementNotFound
        }

        // Already unlocked, don't update again
        guard !achievement.isUnlocked else {
            return []
        }

        var updatedAchievement = achievement
        updatedAchievement.progress = value

        // Check if achievement should be unlocked
        if updatedAchievement.progress >= updatedAchievement.targetValue {
            updatedAchievement.unlockedDate = Date()
        }

        let saved = try await repository.update(updatedAchievement)

        // Return the achievement if it was newly unlocked in this operation
        if saved.isUnlocked && !achievement.isUnlocked {
            return [saved]
        }

        return []
    }
}

/// Errors specific to achievement service operations
enum AchievementServiceError: Error, LocalizedError {
    case achievementNotFound
    case invalidProgress

    var errorDescription: String? {
        switch self {
        case .achievementNotFound:
            return "Achievement not found. Please initialize achievements first."
        case .invalidProgress:
            return "Invalid progress value provided."
        }
    }
}
