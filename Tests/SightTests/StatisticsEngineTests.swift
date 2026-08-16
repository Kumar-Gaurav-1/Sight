import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Clear persisted data to ensure clean state
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        AdherenceManager.shared.resetAllStats()

        engine = StatisticsEngine()
    }

    override func tearDown() {
        // Stop any active sessions
        if engine.currentSession != nil {
            engine.endSession()
        }
        if engine.currentPauseEvent != nil {
            engine.endPause()
        }

        engine = nil
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        AdherenceManager.shared.resetAllStats()

        super.tearDown()
    }

    // MARK: - Session Management Tests

    func testStartSession() {
        XCTAssertNil(engine.currentSession)

        engine.startSession()

        XCTAssertNotNil(engine.currentSession)
        XCTAssertTrue(engine.currentSession!.isActive)
        XCTAssertEqual(engine.todaysSessions.count, 0)
    }

    func testEndSession() {
        engine.startSession()
        let session = engine.currentSession!

        engine.endSession()

        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 1)
        XCTAssertEqual(engine.todaysSessions.first?.id, session.id)
        XCTAssertFalse(engine.todaysSessions.first!.isActive)
    }

    func testStartSessionWhileActiveEndsPrevious() {
        engine.startSession()
        let firstSession = engine.currentSession!

        // Attempt to start another session
        engine.startSession()

        XCTAssertNotEqual(engine.currentSession?.id, firstSession.id)
        XCTAssertEqual(engine.todaysSessions.count, 1)
        XCTAssertEqual(engine.todaysSessions.first?.id, firstSession.id)
    }

    func testEndSessionWhenNoneActive() {
        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 0)

        engine.endSession()

        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 0)
    }

    // MARK: - Break and Nudge Tests

    func testRecordBreakCompleted() {
        engine.startSession()

        engine.recordBreak(completed: true)

        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)
    }

    func testRecordBreakSkipped() {
        engine.startSession()

        engine.recordBreak(completed: false)

        XCTAssertEqual(engine.currentSession?.breaksTaken, 0)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 1)
    }

    func testRecordNudgeFollowed() {
        engine.startSession()

        engine.recordNudge(followed: true)

        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 0)
    }

    func testRecordNudgeDismissed() {
        engine.startSession()

        engine.recordNudge(followed: false)

        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 0)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 1)
    }

    // MARK: - Pause Event Tests

    func testStartPause() {
        engine.startSession()
        XCTAssertNil(engine.currentPauseEvent)

        engine.startPause(reason: .meeting, relatedApp: "Zoom")

        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "Zoom")

        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
    }

    func testEndPause() {
        engine.startSession()
        engine.startPause(reason: .meeting, relatedApp: "Zoom")

        engine.endPause()

        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        // Pause event inside session is now completed
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime)
    }
}
