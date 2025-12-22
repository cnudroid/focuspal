//
//  ChildTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

final class ChildTests: XCTestCase {

    func testChildCreation() {
        let child = TestData.makeChild(name: "Alice", age: 10)

        XCTAssertEqual(child.name, "Alice")
        XCTAssertEqual(child.age, 10)
        XCTAssertEqual(child.avatarId, "avatar_default")
        XCTAssertEqual(child.themeColor, "blue")
        XCTAssertTrue(child.isActive)
    }

    func testChildEquality() {
        let id = UUID()
        let child1 = TestData.makeChild(id: id, name: "Bob")
        let child2 = TestData.makeChild(id: id, name: "Bob")

        XCTAssertEqual(child1, child2)
    }

    func testChildPreferencesDefaults() {
        let preferences = ChildPreferences()

        XCTAssertEqual(preferences.timerVisualization, .circular)
        XCTAssertTrue(preferences.soundsEnabled)
        XCTAssertTrue(preferences.hapticsEnabled)
    }

    func testChildPreferencesEncoding() throws {
        let preferences = ChildPreferences(
            timerVisualization: .bar,
            soundsEnabled: false,
            hapticsEnabled: true
        )

        let data = try JSONEncoder().encode(preferences)
        let decoded = try JSONDecoder().decode(ChildPreferences.self, from: data)

        XCTAssertEqual(decoded.timerVisualization, .bar)
        XCTAssertFalse(decoded.soundsEnabled)
        XCTAssertTrue(decoded.hapticsEnabled)
    }
}
