import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {
    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        engine = StatisticsEngine()
    }

    override func tearDown() {
        AdherenceManager.shared.resetAllStats()
        engine = nil
        super.tearDown()
    }

    func testStartSession() {
        XCTAssertNil(engine.currentSession, "Engine should not have an active session initially")

        engine.startSession()

        XCTAssertNotNil(engine.currentSession, "Engine should have an active session after start")

        let firstSessionId = engine.currentSession?.id

        engine.startSession()
        XCTAssertNotNil(engine.currentSession)
        XCTAssertNotEqual(engine.currentSession?.id, firstSessionId, "Starting an active session should create a new one")
        XCTAssertEqual(engine.todaysSessions.count, 1, "Previous session should be ended and saved")
        XCTAssertEqual(engine.todaysSessions.first?.id, firstSessionId, "Previous session should be correctly stored")
    }

    func testEndSession() {
        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        engine.endSession()

        XCTAssertNil(engine.currentSession, "Engine should not have an active session after end")
        XCTAssertEqual(engine.todaysSessions.count, 1, "Ended session should be added to today's sessions")
    }

    func testRecordBreak() {
        engine.startSession()
        XCTAssertEqual(engine.currentSession?.breaksTaken, 0)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: true)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: false)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 1)
    }

    func testRecordNudge() {
        engine.startSession()
        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 0)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 0)

        engine.recordNudge(followed: true)
        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 0)

        engine.recordNudge(followed: false)
        XCTAssertEqual(engine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(engine.currentSession?.nudgesDismissed, 1)
    }
}
