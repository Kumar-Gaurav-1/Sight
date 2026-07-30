import XCTest
@testable import Sight

final class WorkSessionTests: XCTestCase {

    // MARK: - Initial State Tests

    func testInitialState() {
        let session = WorkSession()

        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 0)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 0)
        XCTAssertTrue(session.pauseEvents.isEmpty)
        XCTAssertTrue(session.isActive)
    }

    // MARK: - Completion Tests

    func testCompleteSession() {
        var session = WorkSession()
        XCTAssertTrue(session.isActive)

        session.complete()

        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTime)
    }

    // MARK: - Record Break Tests

    func testRecordCompletedBreak() {
        var session = WorkSession()
        session.recordBreak(completed: true)

        XCTAssertEqual(session.breaksTaken, 1)
        XCTAssertEqual(session.breaksSkipped, 0)
    }

    func testRecordSkippedBreak() {
        var session = WorkSession()
        session.recordBreak(completed: false)

        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 1)
    }

    func testMultipleBreaks() {
        var session = WorkSession()
        session.recordBreak(completed: true)
        session.recordBreak(completed: true)
        session.recordBreak(completed: false)

        XCTAssertEqual(session.breaksTaken, 2)
        XCTAssertEqual(session.breaksSkipped, 1)
    }

    // MARK: - Record Nudge Tests

    func testRecordFollowedNudge() {
        var session = WorkSession()
        session.recordNudge(followed: true)

        XCTAssertEqual(session.nudgesFollowed, 1)
        XCTAssertEqual(session.nudgesDismissed, 0)
    }

    func testRecordDismissedNudge() {
        var session = WorkSession()
        session.recordNudge(followed: false)

        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 1)
    }

    // MARK: - Derived Properties Tests

    func testCompletionRate() {
        var session = WorkSession()

        // Initial state completion rate is 1.0 (no breaks taken or skipped)
        XCTAssertEqual(session.completionRate, 1.0)

        session.recordBreak(completed: true)
        XCTAssertEqual(session.completionRate, 1.0) // 1 / 1

        session.recordBreak(completed: false)
        XCTAssertEqual(session.completionRate, 0.5) // 1 / 2

        session.recordBreak(completed: true)
        XCTAssertEqual(session.completionRate, 2.0 / 3.0, accuracy: 0.001) // 2 / 3
    }

    // MARK: - Pause Events Tests

    func testAddAndCompletePauseEvent() {
        var session = WorkSession()

        let pause = PauseEvent(reason: .meeting)
        session.addPauseEvent(pause)

        XCTAssertEqual(session.pauseEvents.count, 1)
        XCTAssertNil(session.pauseEvents.first?.endTime)

        session.completePauseEvent()

        XCTAssertNotNil(session.pauseEvents.first?.endTime)
    }

    func testCompletePauseEventWhenEmpty() {
        var session = WorkSession()

        // Should not crash
        session.completePauseEvent()
        XCTAssertTrue(session.pauseEvents.isEmpty)
    }
}
