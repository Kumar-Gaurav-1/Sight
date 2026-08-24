import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Reset defaults to prevent state leakage
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        AdherenceManager.shared.resetAllStats()

        engine = StatisticsEngine()
    }

    override func tearDown() {
        // Clean up active session
        if engine.currentSession != nil {
            engine.endSession()
        }
        if engine.currentPauseEvent != nil {
            engine.endPause()
        }
        engine = nil

        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        AdherenceManager.shared.resetAllStats()

        super.tearDown()
    }

    // MARK: - Session Tests

    func testStartSession() {
        XCTAssertNil(engine.currentSession)

        engine.startSession()

        XCTAssertNotNil(engine.currentSession)
        XCTAssertTrue(engine.currentSession?.isActive ?? false)
    }

    func testStartSessionWhenAlreadyActive() {
        engine.startSession()
        let firstSessionId = engine.currentSession?.id

        // Should ignore second start
        engine.startSession()

        XCTAssertEqual(engine.currentSession?.id, firstSessionId)
    }

    func testEndSession() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)
        let sessionId = engine.currentSession?.id

        engine.endSession()

        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaysSessions.count, 1)
        XCTAssertEqual(engine.todaysSessions.first?.id, sessionId)
        XCTAssertFalse(engine.todaysSessions.first?.isActive ?? true)
    }

    func testEndSessionWhenNoneActive() {
        let initialCount = engine.todaysSessions.count

        engine.endSession()

        XCTAssertEqual(engine.todaysSessions.count, initialCount)
    }

    // MARK: - Break and Nudge Tests

    func testRecordBreak() {
        engine.startSession()

        engine.recordBreak(completed: true)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: false)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 1)
    }

    func testRecordBreakWithoutSession() {
        engine.recordBreak(completed: true)
        // Should not crash, just returns
    }

    func testRecordNudge() {
        engine.startSession()

        engine.recordNudge(followed: true)
        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 0)

        engine.recordNudge(followed: false)
        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 1)
    }

    func testRecordNudgeWithoutSession() {
        engine.recordNudge(followed: true)
        // Should not crash, just returns
    }

    // MARK: - Pause Tests

    func testStartPause() {
        engine.startSession()

        engine.startPause(reason: .meeting, relatedApp: "Zoom")

        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "Zoom")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
    }

    func testStartPauseWhenAlreadyPaused() {
        engine.startSession()
        engine.startPause(reason: .meeting)
        let firstPauseId = engine.currentPauseEvent?.id

        // Should end the first pause and start a new one
        engine.startPause(reason: .manual)

        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertNotEqual(engine.currentPauseEvent?.id, firstPauseId)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .manual)
        // previous pause complete
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 2)
    }

    func testEndPause() {
        engine.startSession()
        engine.startPause(reason: .idle)

        engine.endPause()

        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime)
    }

    func testEndPauseWhenNoneActive() {
        engine.startSession()
        let initialCount = engine.currentSession?.pauseEvents.count ?? 0

        engine.endPause()

        XCTAssertEqual(engine.currentSession?.pauseEvents.count, initialCount)
    }
}
