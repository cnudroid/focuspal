//
//  CategoryTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

final class CategoryTests: XCTestCase {

    func testCategoryCreation() {
        let childId = UUID()
        let category = TestData.makeCategory(
            name: "Homework",
            iconName: "book.fill",
            colorHex: "#4A90D9",
            childId: childId
        )

        XCTAssertEqual(category.name, "Homework")
        XCTAssertEqual(category.iconName, "book.fill")
        XCTAssertEqual(category.colorHex, "#4A90D9")
        XCTAssertEqual(category.childId, childId)
        XCTAssertTrue(category.isActive)
        XCTAssertFalse(category.isSystem)
    }

    func testDefaultCategories() {
        let childId = UUID()
        let categories = Category.defaultCategories(for: childId)

        XCTAssertEqual(categories.count, 6)

        // Verify all categories belong to the child
        for category in categories {
            XCTAssertEqual(category.childId, childId)
            XCTAssertTrue(category.isSystem)
            XCTAssertTrue(category.isActive)
        }

        // Verify specific categories exist
        let names = categories.map { $0.name }
        XCTAssertTrue(names.contains("Homework"))
        XCTAssertTrue(names.contains("Reading"))
        XCTAssertTrue(names.contains("Screen Time"))
        XCTAssertTrue(names.contains("Playing"))
        XCTAssertTrue(names.contains("Sports"))
        XCTAssertTrue(names.contains("Music"))
    }

    func testCategorySortOrder() {
        let childId = UUID()
        let categories = Category.defaultCategories(for: childId)

        // Verify sort order is sequential
        for (index, category) in categories.enumerated() {
            XCTAssertEqual(category.sortOrder, index)
        }
    }

    func testSubcategoryParent() {
        let parentId = UUID()
        let childId = UUID()

        let subcategory = TestData.makeCategory(
            name: "Math Homework",
            parentCategoryId: parentId,
            childId: childId
        )

        XCTAssertEqual(subcategory.parentCategoryId, parentId)
    }
}
