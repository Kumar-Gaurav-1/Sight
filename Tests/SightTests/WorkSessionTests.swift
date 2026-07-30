import XCTest
@testable import Sight

final class WorkSessionTests: XCTestCase {

    func testInitialState() {
        let session = WorkSession()
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 0)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 0)
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)
        XCTAssertTrue(session.pauseEvents.isEmpty)
    }

    func testRecordBreakCompleted() {
        var session = WorkSession()
        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 1)
        XCTAssertEqual(session.breaksSkipped, 0)

        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 2)
        XCTAssertEqual(session.breaksSkipped, 0)
    }

    func testRecordBreakSkipped() {
        var session = WorkSession()
        session.recordBreak(completed: false)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 1)

        session.recordBreak(completed: false)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 2)
    }

    func testRecordBreakMixed() {
        var session = WorkSession()
        session.recordBreak(completed: true)
        session.recordBreak(completed: false)
        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 2)
        XCTAssertEqual(session.breaksSkipped, 1)
    }

    func testRecordNudgeFollowed() {
        var session = WorkSession()
        session.recordNudge(followed: true)
        XCTAssertEqual(session.nudgesFollowed, 1)
        XCTAssertEqual(session.nudgesDismissed, 0)

        session.recordNudge(followed: true)
        XCTAssertEqual(session.nudgesFollowed, 2)
        XCTAssertEqual(session.nudgesDismissed, 0)
    }

    func testRecordNudgeDismissed() {
        var session = WorkSession()
        session.recordNudge(followed: false)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 1)

        session.recordNudge(followed: false)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 2)
    }

    func testRecordNudgeMixed() {
        var session = WorkSession()
        session.recordNudge(followed: true)
        session.recordNudge(followed: false)
        session.recordNudge(followed: true)
        XCTAssertEqual(session.nudgesFollowed, 2)
        XCTAssertEqual(session.nudgesDismissed, 1)
    }

    func testSessionComplete() {
        var session = WorkSession()
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)

        session.complete()

        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTime)
    }
}
