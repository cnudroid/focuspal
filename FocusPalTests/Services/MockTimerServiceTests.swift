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
        XCTAssertEqual(sut.mockTimerState, .idle)
        XCTAssertEqual(sut.mockRemainingTime, 0)
    }

    func testStartTimer() {
        sut.startTimer(duration: 300, mode: .countdown(duration: 300), category: nil)

        XCTAssertEqual(sut.mockTimerState, .running)
        XCTAssertEqual(sut.mockRemainingTime, 300)
        XCTAssertEqual(sut.startTimerCallCount, 1)
    }

    func testPauseTimer() {
        sut.startTimer(duration: 300, mode: .countdown(duration: 300), category: nil)
        sut.pauseTimer()

        XCTAssertEqual(sut.mockTimerState, .paused)
        XCTAssertEqual(sut.pauseTimerCallCount, 1)
    }

    func testResumeTimer() {
        sut.startTimer(duration: 300, mode: .countdown(duration: 300), category: nil)
        sut.pauseTimer()
        sut.resumeTimer()

        XCTAssertEqual(sut.mockTimerState, .running)
        XCTAssertEqual(sut.resumeTimerCallCount, 1)
    }

    func testStopTimer() {
        sut.startTimer(duration: 300, mode: .countdown(duration: 300), category: nil)
        sut.stopTimer()

        XCTAssertEqual(sut.mockTimerState, .idle)
        XCTAssertEqual(sut.mockRemainingTime, 0)
        XCTAssertEqual(sut.stopTimerCallCount, 1)
    }

    func testReset() {
        sut.startTimer(duration: 300, mode: .countdown(duration: 300), category: nil)
        sut.reset()

        XCTAssertEqual(sut.mockTimerState, .idle)
        XCTAssertEqual(sut.mockRemainingTime, 0)
        XCTAssertEqual(sut.startTimerCallCount, 0)
    }

    func testSimulateTimerComplete() {
        sut.startTimer(duration: 60, mode: .countdown(duration: 60), category: nil)
        sut.simulateTimerComplete()

        XCTAssertEqual(sut.mockTimerState, .completed)
        XCTAssertEqual(sut.mockRemainingTime, 0)
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

        sut.startTimer(duration: 60, mode: .countdown(duration: 60), category: nil)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(states.contains(.idle))
        XCTAssertTrue(states.contains(.running))
    }
}
