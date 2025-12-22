//
//  FocusPalTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

/// Main test class - serves as entry point and integration test container
final class FocusPalTests: XCTestCase {

    override func setUpWithError() throws {
        // Reset test data before each test
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    // MARK: - Smoke Tests

    func testModelsCanBeInstantiated() throws {
        // Verify all domain models can be created
        let child = TestData.makeChild()
        let category = TestData.makeCategory(childId: child.id)
        let activity = TestData.makeActivity(categoryId: category.id, childId: child.id)
        let timeGoal = TestData.makeTimeGoal(categoryId: category.id, childId: child.id)
        let achievement = TestData.makeAchievement(childId: child.id)

        XCTAssertNotNil(child)
        XCTAssertNotNil(category)
        XCTAssertNotNil(activity)
        XCTAssertNotNil(timeGoal)
        XCTAssertNotNil(achievement)
    }

    func testDefaultCategoriesAreCreated() throws {
        let childId = UUID()
        let categories = Category.defaultCategories(for: childId)

        XCTAssertFalse(categories.isEmpty)
        XCTAssertEqual(categories.count, 6)
    }

    func testAchievementTypesExist() throws {
        let types = AchievementType.allCases

        XCTAssertFalse(types.isEmpty)
        XCTAssertEqual(types.count, 8)
    }
}
