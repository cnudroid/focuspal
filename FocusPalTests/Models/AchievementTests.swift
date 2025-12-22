//
//  AchievementTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

final class AchievementTests: XCTestCase {

    func testAchievementCreation() {
        let achievement = TestData.makeAchievement(
            achievementTypeId: AchievementType.streak7Day.rawValue,
            progress: 3,
            targetValue: 7
        )

        XCTAssertEqual(achievement.achievementTypeId, "streak_7day")
        XCTAssertEqual(achievement.progress, 3)
        XCTAssertEqual(achievement.targetValue, 7)
    }

    func testIsUnlocked() {
        let locked = TestData.makeAchievement(unlockedDate: nil)
        let unlocked = TestData.makeAchievement(unlockedDate: Date())

        XCTAssertFalse(locked.isUnlocked)
        XCTAssertTrue(unlocked.isUnlocked)
    }

    func testProgressPercentage() {
        let achievement = TestData.makeAchievement(
            progress: 3,
            targetValue: 10
        )

        XCTAssertEqual(achievement.progressPercentage, 30, accuracy: 0.01)
    }

    func testProgressPercentageCapsAt100() {
        let achievement = TestData.makeAchievement(
            progress: 15,
            targetValue: 10
        )

        XCTAssertEqual(achievement.progressPercentage, 100, accuracy: 0.01)
    }

    func testAchievementTypeNames() {
        XCTAssertEqual(AchievementType.streak3Day.name, "3-Day Streak")
        XCTAssertEqual(AchievementType.homeworkHero.name, "Homework Hero")
        XCTAssertEqual(AchievementType.firstTimer.name, "First Timer")
    }

    func testAchievementTypeTargetValues() {
        XCTAssertEqual(AchievementType.streak3Day.targetValue, 3)
        XCTAssertEqual(AchievementType.streak7Day.targetValue, 7)
        XCTAssertEqual(AchievementType.homeworkHero.targetValue, 600) // minutes
    }
}
