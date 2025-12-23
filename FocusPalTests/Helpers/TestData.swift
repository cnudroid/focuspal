//
//  TestData.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import Foundation
@testable import FocusPal

/// Factory for creating test data
enum TestData {

    // MARK: - Child

    static func makeChild(
        id: UUID = UUID(),
        name: String = "Test Child",
        age: Int = 8,
        avatarId: String = "avatar_default",
        themeColor: String = "blue",
        preferences: ChildPreferences = ChildPreferences(),
        createdDate: Date = Date(),
        lastActiveDate: Date? = nil,
        isActive: Bool = true
    ) -> Child {
        Child(
            id: id,
            name: name,
            age: age,
            avatarId: avatarId,
            themeColor: themeColor,
            preferences: preferences,
            createdDate: createdDate,
            lastActiveDate: lastActiveDate,
            isActive: isActive
        )
    }

    // MARK: - Category

    static func makeCategory(
        id: UUID = UUID(),
        name: String = "Test Category",
        iconName: String = "folder.fill",
        colorHex: String = "#4A90D9",
        isActive: Bool = true,
        sortOrder: Int = 0,
        isSystem: Bool = false,
        parentCategoryId: UUID? = nil,
        childId: UUID = UUID()
    ) -> FocusPal.Category {
        FocusPal.Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: isActive,
            sortOrder: sortOrder,
            isSystem: isSystem,
            parentCategoryId: parentCategoryId,
            childId: childId
        )
    }

    // MARK: - Activity

    static func makeActivity(
        id: UUID = UUID(),
        categoryId: UUID = UUID(),
        childId: UUID = UUID(),
        startTime: Date = Date().addingTimeInterval(-3600),
        endTime: Date = Date(),
        notes: String? = nil,
        mood: Mood = .neutral,
        isManualEntry: Bool = false,
        createdDate: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) -> Activity {
        Activity(
            id: id,
            categoryId: categoryId,
            childId: childId,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            mood: mood,
            isManualEntry: isManualEntry,
            createdDate: createdDate,
            syncStatus: syncStatus
        )
    }

    // MARK: - TimeGoal

    static func makeTimeGoal(
        id: UUID = UUID(),
        categoryId: UUID = UUID(),
        childId: UUID = UUID(),
        recommendedMinutes: Int = 60,
        warningThreshold: Int = 80,
        isActive: Bool = true,
        createdDate: Date = Date()
    ) -> TimeGoal {
        TimeGoal(
            id: id,
            categoryId: categoryId,
            childId: childId,
            recommendedMinutes: recommendedMinutes,
            warningThreshold: warningThreshold,
            isActive: isActive,
            createdDate: createdDate
        )
    }

    // MARK: - Achievement

    static func makeAchievement(
        id: UUID = UUID(),
        achievementTypeId: String = AchievementType.firstTimer.rawValue,
        childId: UUID = UUID(),
        unlockedDate: Date? = nil,
        progress: Int = 0,
        targetValue: Int = 1
    ) -> Achievement {
        Achievement(
            id: id,
            achievementTypeId: achievementTypeId,
            childId: childId,
            unlockedDate: unlockedDate,
            progress: progress,
            targetValue: targetValue
        )
    }
}
