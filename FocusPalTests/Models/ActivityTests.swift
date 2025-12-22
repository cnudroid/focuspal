//
//  ActivityTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
@testable import FocusPal

final class ActivityTests: XCTestCase {

    func testActivityCreation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hour later

        let activity = TestData.makeActivity(
            startTime: startTime,
            endTime: endTime,
            notes: "Did homework"
        )

        XCTAssertEqual(activity.startTime, startTime)
        XCTAssertEqual(activity.endTime, endTime)
        XCTAssertEqual(activity.notes, "Did homework")
    }

    func testActivityDuration() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1800) // 30 minutes

        let activity = TestData.makeActivity(
            startTime: startTime,
            endTime: endTime
        )

        XCTAssertEqual(activity.duration, 1800, accuracy: 0.001)
        XCTAssertEqual(activity.durationMinutes, 30)
    }

    func testMoodEmoji() {
        XCTAssertEqual(Mood.none.emoji, "")
        XCTAssertEqual(Mood.verySad.emoji, "😢")
        XCTAssertEqual(Mood.sad.emoji, "😕")
        XCTAssertEqual(Mood.neutral.emoji, "😐")
        XCTAssertEqual(Mood.happy.emoji, "😊")
        XCTAssertEqual(Mood.veryHappy.emoji, "😄")
    }

    func testMoodRawValues() {
        XCTAssertEqual(Mood.none.rawValue, 0)
        XCTAssertEqual(Mood.veryHappy.rawValue, 5)
    }

    func testSyncStatusEncoding() throws {
        let statuses: [SyncStatus] = [.synced, .pending, .conflict]

        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(SyncStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}
