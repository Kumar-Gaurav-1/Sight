import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults keys used by StatisticsEngine
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        // Reset AdherenceManager singleton state
        AdherenceManager.shared.resetAllStats()

        engine = StatisticsEngine()
    }

    override func tearDown() {
        engine = nil
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")
        AdherenceManager.shared.resetAllStats()
        super.tearDown()
    }

    func testStartSession() {
        XCTAssertNil(engine.currentSession, "Engine should start with no active session")

        engine.startSession()
        XCTAssertNotNil(engine.currentSession, "Engine should have an active session after start")
        XCTAssertEqual(engine.todaysSessions.count, 0, "No completed sessions yet")

        // Try starting again - should end the previous session and start a new one
        let firstSessionId = engine.currentSession?.id
        engine.startSession()

        XCTAssertNotEqual(engine.currentSession?.id, firstSessionId, "Session ID should change on second start call")
        XCTAssertEqual(engine.todaysSessions.count, 1, "Previous session should be added to completed sessions")
    }

    func testEndSession() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        engine.endSession()
        XCTAssertNil(engine.currentSession, "Session should be nil after ending")
        XCTAssertEqual(engine.todaysSessions.count, 1, "Completed session should be added to todaysSessions")

        // Try ending again - should be safe
        engine.endSession()
        XCTAssertEqual(engine.todaysSessions.count, 1, "Should not add another session if none was active")
    }

    func testRecordBreak() {
        engine.startSession()

        engine.recordBreak(completed: true)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1, "Should have 1 taken break")
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: false)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 1, "Should have 1 skipped break")
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

    func testPauseTracking() {
        engine.startSession()

        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 0)

        engine.startPause(reason: .meeting, relatedApp: "Zoom")
        XCTAssertNotNil(engine.currentPauseEvent, "Should have an active pause event")
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "Zoom")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1, "Pause event should be added to session")

        engine.endPause()
        XCTAssertNil(engine.currentPauseEvent, "Should have no active pause event after ending")
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime, "Pause event in session should have an end time")
    }
}
