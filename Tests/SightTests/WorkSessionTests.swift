import XCTest
@testable import Sight

final class WorkSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        let session = WorkSession()
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 0)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 0)
        XCTAssertTrue(session.pauseEvents.isEmpty)
    }

    // MARK: - State Mutation Tests

    func testComplete() {
        var session = WorkSession()
        session.complete()
        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTime)
    }

    func testRecordBreak() {
        var session = WorkSession()
        session.recordBreak(completed: true)
        session.recordBreak(completed: true)
        session.recordBreak(completed: false)

        XCTAssertEqual(session.breaksTaken, 2)
        XCTAssertEqual(session.breaksSkipped, 1)
    }

    func testRecordNudge() {
        var session = WorkSession()
        session.recordNudge(followed: true)
        session.recordNudge(followed: false)
        session.recordNudge(followed: false)

        XCTAssertEqual(session.nudgesFollowed, 1)
        XCTAssertEqual(session.nudgesDismissed, 2)
    }

    func testPauseEvents() {
        var session = WorkSession()
        let pause = PauseEvent(reason: .meeting)
        session.addPauseEvent(pause)

        XCTAssertEqual(session.pauseEvents.count, 1)
        XCTAssertEqual(session.pauseEvents.first?.reason, .meeting)
        XCTAssertNil(session.pauseEvents.first?.endTime)

        session.completePauseEvent()
        XCTAssertNotNil(session.pauseEvents.first?.endTime)
    }

    // MARK: - Calculation Tests

    func testDurationCalculations() {
        var session = WorkSession()
        session.endTime = session.startTime.addingTimeInterval(3600) // 1 hour

        XCTAssertEqual(session.totalDurationSeconds, 3600)
        XCTAssertEqual(session.totalDurationMinutes, 60)

        var pause = PauseEvent(reason: .idle)
        pause.endTime = pause.timestamp.addingTimeInterval(600) // 10 minutes
        session.addPauseEvent(pause)

        XCTAssertEqual(session.activeDurationSeconds, 3000)
    }

    func testCompletionRate() {
        var session = WorkSession()
        XCTAssertEqual(session.completionRate, 1.0)

        session.recordBreak(completed: true)
        session.recordBreak(completed: true)
        session.recordBreak(completed: false)
        session.recordBreak(completed: false)

        XCTAssertEqual(session.completionRate, 0.5)
    }

    func testBreakIntervals() {
        var session = WorkSession()
        XCTAssertEqual(session.averageBreakInterval, 0)

        session.endTime = session.startTime.addingTimeInterval(7200) // 2 hours
        XCTAssertEqual(session.longestFocusStretch, 7200)

        session.recordBreak(completed: true)
        session.recordBreak(completed: true)

        XCTAssertEqual(session.averageBreakInterval, 3600)
        XCTAssertEqual(session.longestFocusStretch, 3600 * 1.5)
    }
}
