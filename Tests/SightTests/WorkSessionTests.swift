import XCTest
@testable import Sight

final class WorkSessionTests: XCTestCase {

    func testInitialState() {
        let session = WorkSession()

        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.breaksTaken, 0)
        XCTAssertEqual(session.breaksSkipped, 0)
        XCTAssertEqual(session.nudgesFollowed, 0)
        XCTAssertEqual(session.nudgesDismissed, 0)
        XCTAssertTrue(session.pauseEvents.isEmpty)
        XCTAssertEqual(session.completionRate, 1.0)
    }

    func testCompleteSession() {
        var session = WorkSession()
        XCTAssertTrue(session.isActive)

        session.complete()

        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTime)
    }

    func testRecordBreak() {
        var session = WorkSession()

        // Record completed break
        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 1)
        XCTAssertEqual(session.breaksSkipped, 0)

        // Record skipped break
        session.recordBreak(completed: false)
        XCTAssertEqual(session.breaksTaken, 1)
        XCTAssertEqual(session.breaksSkipped, 1)

        // Check completion rate (1 taken / 2 total = 0.5)
        XCTAssertEqual(session.completionRate, 0.5)

        // Another completed break
        session.recordBreak(completed: true)
        XCTAssertEqual(session.breaksTaken, 2)
        XCTAssertEqual(session.breaksSkipped, 1)

        // Check completion rate (2 taken / 3 total = 0.66...)
        XCTAssertEqual(session.completionRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func testRecordNudge() {
        var session = WorkSession()

        // Record followed nudge
        session.recordNudge(followed: true)
        XCTAssertEqual(session.nudgesFollowed, 1)
        XCTAssertEqual(session.nudgesDismissed, 0)

        // Record dismissed nudge
        session.recordNudge(followed: false)
        XCTAssertEqual(session.nudgesFollowed, 1)
        XCTAssertEqual(session.nudgesDismissed, 1)
    }

    func testDurations() {
        var session = WorkSession()

        // Mock a past start time (1 hour ago)
        let pastDate = Date().addingTimeInterval(-3600)
        // Set the property via mirror or initialization if it were not private/internal
        // WorkSession doesn't have an initializer with date, but since we can test the logic
        // by completing the session at a specific time, let's complete it immediately for an active duration of roughly 0

        // Let's rely on TimeInterval
        // Since startTime is set in init() and not mutable, we wait a tiny bit or just mock the Date
        // Actually we can't easily mock Date() in Swift without dependency injection.
        // But we can check that totalDurationSeconds is >= 0
        XCTAssertGreaterThanOrEqual(session.totalDurationSeconds, 0)

        // Mocking pause events
        var pauseEvent1 = PauseEvent(reason: .meeting)
        var pauseEvent2 = PauseEvent(reason: .idle)

        // Complete the pause events with a known duration.
        // Since timestamp is set internally to Date(), we can complete it and modify its internal time or rely on its actual duration.
        // PauseEvent.endTime is mutable
        pauseEvent1.endTime = pauseEvent1.timestamp.addingTimeInterval(300) // 5 minutes
        pauseEvent2.endTime = pauseEvent2.timestamp.addingTimeInterval(600) // 10 minutes

        session.addPauseEvent(pauseEvent1)
        session.addPauseEvent(pauseEvent2)

        // Active duration should be total duration - pause duration
        let pauseTime = session.pauseEvents.reduce(0) { $0 + Int($1.duration) }
        XCTAssertEqual(pauseTime, 900)

        // Because total duration is likely close to 0 seconds, total - pauseTime will be negative,
        // but activeDurationSeconds uses max(0, ...), so it should be 0.
        XCTAssertEqual(session.activeDurationSeconds, 0)
    }

    func testAverageBreakIntervalAndFocusStretch() {
        var session = WorkSession()

        XCTAssertEqual(session.averageBreakInterval, 0)

        // Active duration is ~0. With 1 break, interval should be 0
        session.recordBreak(completed: true)
        XCTAssertEqual(session.averageBreakInterval, 0)

        // longestFocusStretch = averageBreakInterval * 1.5 = 0 * 1.5 = 0
        XCTAssertEqual(session.longestFocusStretch, 0)
    }

    func testPauseEventCompletion() {
        var session = WorkSession()
        let pauseEvent = PauseEvent(reason: .manual)

        session.addPauseEvent(pauseEvent)
        XCTAssertNil(session.pauseEvents.last?.endTime)

        session.completePauseEvent()
        XCTAssertNotNil(session.pauseEvents.last?.endTime)
    }
}
