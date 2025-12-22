//
//  TimeGoalTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

final class TimeGoalTests: XCTestCase {

    func testTimeGoalCreation() {
        let goal = TestData.makeTimeGoal(
            recommendedMinutes: 120,
            warningThreshold: 75
        )

        XCTAssertEqual(goal.recommendedMinutes, 120)
        XCTAssertEqual(goal.warningThreshold, 75)
        XCTAssertTrue(goal.isActive)
    }

    func testShouldWarn() {
        let goal = TestData.makeTimeGoal(
            recommendedMinutes: 100,
            warningThreshold: 80
        )

        // Below threshold (79 minutes out of 100 with 80% threshold = 79%)
        XCTAssertFalse(goal.shouldWarn(currentMinutes: 79))

        // At threshold (80 minutes = 80%)
        XCTAssertTrue(goal.shouldWarn(currentMinutes: 80))

        // Above threshold
        XCTAssertTrue(goal.shouldWarn(currentMinutes: 90))
    }

    func testIsExceeded() {
        let goal = TestData.makeTimeGoal(recommendedMinutes: 60)

        XCTAssertFalse(goal.isExceeded(currentMinutes: 59))
        XCTAssertTrue(goal.isExceeded(currentMinutes: 60))
        XCTAssertTrue(goal.isExceeded(currentMinutes: 61))
    }

    func testProgressPercentage() {
        let goal = TestData.makeTimeGoal(recommendedMinutes: 100)

        XCTAssertEqual(goal.progressPercentage(currentMinutes: 0), 0, accuracy: 0.01)
        XCTAssertEqual(goal.progressPercentage(currentMinutes: 50), 50, accuracy: 0.01)
        XCTAssertEqual(goal.progressPercentage(currentMinutes: 100), 100, accuracy: 0.01)
        // Should cap at 100
        XCTAssertEqual(goal.progressPercentage(currentMinutes: 150), 100, accuracy: 0.01)
    }
}
