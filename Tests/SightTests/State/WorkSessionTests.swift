import XCTest
@testable import Sight

final class WorkSessionTests: XCTestCase {

    func testInitialization() {
        let session = WorkSession()
        XCTAssertNotNil(session.id)
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 0)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 0)
        XCTAssertTrue(session.pauseEvents.isEmpty)
        XCTAssertEqual(session.completionRate, 1.0)
    }

    func testComplete() {
        var session = WorkSession()
        session.complete()
        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTime)
    }

    func testRecordBreakCompleted() {
        var session = WorkSession()
        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 1)
        XCTAssertEqual(session.breaksSkipped, 0)
        XCTAssertEqual(session.completionRate, 1.0)
    }

    func testRecordBreakSkipped() {
        var session = WorkSession()
        session.recordBreak(completed: false)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 1)
        XCTAssertEqual(session.completionRate, 0.0)
    }

    func testRecordBreakMixed() {
        var session = WorkSession()
        session.recordBreak(completed: true)
        session.recordBreak(completed: false)
        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 2)
        XCTAssertEqual(session.breaksSkipped, 1)
        XCTAssertEqual(session.completionRate, 2.0 / 3.0)
    }

    func testRecordNudgeFollowed() {
        var session = WorkSession()
        session.recordNudge(followed: true)
        XCTAssertEqual(session.nudgesFollowed, 1)
        XCTAssertEqual(session.nudgesDismissed, 0)
    }

    func testRecordNudgeDismissed() {
        var session = WorkSession()
        session.recordNudge(followed: false)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 1)
    }

    func testPauseEvents() {
        var session = WorkSession()
        let event = PauseEvent(reason: .meeting, relatedApp: "Zoom")
        session.addPauseEvent(event)
        XCTAssertEqual(session.pauseEvents.count, 1)
        XCTAssertNil(session.pauseEvents[0].endTime)

        session.completePauseEvent()
        XCTAssertEqual(session.pauseEvents.count, 1)
        XCTAssertNotNil(session.pauseEvents[0].endTime)
    }
}
