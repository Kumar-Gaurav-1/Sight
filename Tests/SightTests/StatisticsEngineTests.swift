import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()

        // Clear UserDefaults data to ensure clean state
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        AdherenceManager.shared.resetAllStats()

        engine = StatisticsEngine()
    }

    override func tearDown() {
        engine = nil
        AdherenceManager.shared.resetAllStats()

        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        super.tearDown()
    }

    func testStartSession() {
        XCTAssertNil(engine.currentSession)

        engine.startSession()

        XCTAssertNotNil(engine.currentSession)
        XCTAssertTrue(engine.currentSession!.isActive)
        XCTAssertEqual(engine.todaysSessions.count, 0)
    }

    func testStartSessionWhenAlreadyActive() {
        engine.startSession()
        let initialSessionId = engine.currentSession?.id
        XCTAssertNotNil(initialSessionId)

        // Starting a session while one is active should end the first one and start a new one
        engine.startSession()

        XCTAssertNotEqual(engine.currentSession?.id, initialSessionId)
        XCTAssertEqual(engine.todaysSessions.count, 1)
        XCTAssertEqual(engine.todaysSessions.first?.id, initialSessionId)
    }

    func testEndSession() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)
        let sessionId = engine.currentSession?.id

        engine.endSession()

        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 1)
        XCTAssertEqual(engine.todaysSessions.first?.id, sessionId)
        XCTAssertFalse(engine.todaysSessions.first!.isActive)
    }

    func testEndSessionWhenNoActiveSession() {
        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 0)

        // Ending a session when none is active should do nothing
        engine.endSession()

        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 0)
    }

    func testRecordBreak() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        XCTAssertEqual(engine.currentSession?.breaksTaken, 0)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: true)

        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: false)

        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 1)
    }

    func testRecordBreakWhenNoSessionActive() {
        XCTAssertNil(engine.currentSession)

        // Recording a break without an active session should do nothing (to the session)
        engine.recordBreak(completed: true)

        XCTAssertNil(engine.currentSession)
    }

    func testRecordNudge() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 0)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 0)

        engine.recordNudge(followed: true)

        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 0)

        engine.recordNudge(followed: false)

        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 1)
    }

    func testRecordNudgeWhenNoSessionActive() {
        XCTAssertNil(engine.currentSession)

        // Recording a nudge without an active session should do nothing
        engine.recordNudge(followed: true)

        XCTAssertNil(engine.currentSession)
    }

    func testPauseEvents() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 0)

        engine.startPause(reason: .meeting, relatedApp: "Zoom")

        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "Zoom")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)

        engine.endPause()

        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime)
    }

    func testStartPauseWhenAlreadyPaused() {
        engine.startSession()

        engine.startPause(reason: .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)

        // Starting another pause while one is active should complete the first and start the new one
        engine.startPause(reason: .manual)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .manual)

        // Session should have both pause events (first completed, second active)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 2)
        XCTAssertNotNil(engine.currentSession?.pauseEvents[0].endTime)
        XCTAssertNil(engine.currentSession?.pauseEvents[1].endTime)
    }
}
