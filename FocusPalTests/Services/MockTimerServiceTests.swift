//
//  MockTimerServiceTests.swift
//  FocusPalTests
//
//  Created by FocusPal Team
//

import XCTest
import Combine
@testable import FocusPal

final class MockTimerServiceTests: XCTestCase {
    var sut: MockTimerService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = MockTimerService()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.remainingTime, 0)
        XCTAssertNil(sut.currentCategoryId)
    }

    func testStartTimer() {
        let categoryId = UUID()

        sut.start(duration: 300, categoryId: categoryId)

        XCTAssertEqual(sut.timerState, .running)
        XCTAssertEqual(sut.remainingTime, 300)
        XCTAssertEqual(sut.currentCategoryId, categoryId)
    }

    func testPauseTimer() {
        sut.start(duration: 300, categoryId: UUID())
        sut.pause()

        XCTAssertEqual(sut.timerState, .paused)
    }

    func testResumeTimer() {
        sut.start(duration: 300, categoryId: UUID())
        sut.pause()
        sut.resume()

        XCTAssertEqual(sut.timerState, .running)
    }

    func testStopTimer() {
        sut.start(duration: 300, categoryId: UUID())
        sut.stop()

        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.remainingTime, 0)
    }

    func testReset() {
        sut.start(duration: 300, categoryId: UUID())
        sut.remainingTime = 100
        sut.reset()

        XCTAssertEqual(sut.remainingTime, 300)
        XCTAssertEqual(sut.timerState, .idle)
    }

    func testTimerStatePublisher() {
        let expectation = XCTestExpectation(description: "State published")
        var states: [TimerState] = []

        sut.timerStatePublisher
            .sink { state in
                states.append(state)
                if states.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.start(duration: 60, categoryId: UUID())

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(states.contains(.idle))
        XCTAssertTrue(states.contains(.running))
    }
}
