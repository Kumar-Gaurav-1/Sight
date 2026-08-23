import XCTest
@testable import Sight

@MainActor final class StatisticsEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")
        AdherenceManager.shared.resetAllStats()
    }

    override func tearDown() {
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        super.tearDown()
    }

    func testStartPause() {
        let engine = StatisticsEngine()

        if engine.currentSession != nil {
            engine.endSession()
        }

        engine.startSession()
        XCTAssertNotNil(engine.currentSession, "Session should be started")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 0, "Initial session should have no pause events")
        XCTAssertNil(engine.currentPauseEvent, "Initial pause event should be nil")

        // Start a pause
        engine.startPause(reason: .meeting, relatedApp: "Zoom")

        XCTAssertNotNil(engine.currentPauseEvent, "Current pause event should be set")
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "Zoom")

        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1, "A pause event should be added to the current session")
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.reason, .meeting)
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.relatedApp, "Zoom")
        XCTAssertNil(engine.currentSession?.pauseEvents.first?.endTime, "Pause event should not be completed yet")

        // Start another pause while one is active
        engine.startPause(reason: .focusMode)

        XCTAssertNil(engine.currentPauseEvent, "Current pause event should be nil after ending the previous one")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1, "No new pause event should be added because the previous one was completed instead")
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime, "The first pause event should now be completed")
    }
}
