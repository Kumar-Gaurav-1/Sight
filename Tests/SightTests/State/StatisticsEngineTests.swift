import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {
    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        AdherenceManager.shared.resetAllStats()

        engine = StatisticsEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertNil(engine.currentSession)
        XCTAssertTrue(engine.todaySessions.isEmpty)
        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertTrue(engine.insights.isEmpty)
    }

    func testStartSession() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)
        XCTAssertTrue(engine.currentSession!.isActive)
    }

    func testEndSession() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        engine.endSession()
        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaySessions.count, 1)
        XCTAssertFalse(engine.todaySessions[0].isActive)
    }

    func testStartMultipleSessionsDoesNotOverwrite() {
        engine.startSession()
        let firstSessionId = engine.currentSession?.id

        engine.startSession()
        XCTAssertEqual(engine.currentSession?.id, firstSessionId)
    }

    func testEndSessionWithoutActiveSession() {
        engine.endSession()
        XCTAssertTrue(engine.todaySessions.isEmpty)
    }

    func testRecordBreakAndNudge() {
        engine.startSession()

        engine.recordBreak(completed: true)
        engine.recordBreak(completed: false)

        engine.recordNudge(followed: true)
        engine.recordNudge(followed: true)
        engine.recordNudge(followed: false)

        let session = engine.currentSession
        XCTAssertEqual(session?.breaksTaken, 1)
        XCTAssertEqual(session?.breaksSkipped, 1)

        XCTAssertEqual(session?.nudgesFollowed, 2)
        XCTAssertEqual(session?.nudgesDismissed, 1)
    }

    func testPauseAndEndPause() {
        engine.startSession()

        engine.startPause(reason: .meeting)
        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)

        engine.startPause(reason: .idle)
        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .idle)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.reason, .meeting)

        engine.endPause()
        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 2)
        XCTAssertEqual(engine.currentSession?.pauseEvents.last?.reason, .idle)
    }
}
