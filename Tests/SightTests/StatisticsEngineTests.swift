import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults state to start fresh. Confirmed keys: TodayWorkSessions, SessionsDate, StatsLastResetDate.
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        // Reset AdherenceManager stats which are used by StatisticsEngine
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        engine = StatisticsEngine()

        // Reset state for shared instance as well just in case
        if StatisticsEngine.shared.currentSession != nil {
            StatisticsEngine.shared.endSession()
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    func testStartSession() {
        XCTAssertNil(engine.currentSession)

        engine.startSession()

        XCTAssertNotNil(engine.currentSession)
        XCTAssertTrue(engine.currentSession!.isActive)

        let initialSessionId = engine.currentSession!.id

        // Trying to start again shouldn't do anything
        engine.startSession()

        XCTAssertEqual(engine.currentSession?.id, initialSessionId)
    }

    func testEndSession() {
        // Ending without starting shouldn't crash or add to todaySessions
        engine.endSession()
        XCTAssertTrue(engine.todaySessions.isEmpty)

        engine.startSession()
        XCTAssertNotNil(engine.currentSession)

        engine.endSession()

        XCTAssertNil(engine.currentSession)
        XCTAssertEqual(engine.todaySessions.count, 1)
        XCTAssertFalse(engine.todaySessions[0].isActive)
    }

    func testRecordBreak() {
        engine.startSession()

        engine.recordBreak(completed: true)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 0)

        engine.recordBreak(completed: false)
        XCTAssertEqual(engine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(engine.currentSession?.breaksSkipped, 1)
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

    func testPauseManagement() {
        engine.startSession()
        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 0)

        engine.startPause(reason: .meeting)

        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)

        engine.endPause()

        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        XCTAssertNotNil(engine.currentSession?.pauseEvents[0].endTime)
    }

    func testPersistenceAndLoading() {
        // Create an engine, add a session
        let engine1 = StatisticsEngine()
        engine1.startSession()
        engine1.recordBreak(completed: true)

        // Let background persistence finish
        let exp = expectation(description: "Persistence")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        // Load with a new engine
        let engine2 = StatisticsEngine()
        XCTAssertNotNil(engine2.currentSession)
        XCTAssertEqual(engine2.currentSession?.breaksTaken, 1)
    }
}
