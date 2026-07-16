import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Clear user defaults to prevent state pollution
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        engine = StatisticsEngine()
    }

    override func tearDown() {
        // Clear user defaults again
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        engine = nil
        super.tearDown()
    }

    func testStartPauseWhenNoPauseActive() {
        // Given
        engine.startSession() // Need a session to record pauses
        XCTAssertNil(engine.currentPauseEvent)

        // When
        engine.startPause(reason: .meeting, relatedApp: "Zoom")

        // Then
        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "Zoom")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.reason, .meeting)
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.relatedApp, "Zoom")
    }

    func testStartPauseWhenPauseAlreadyActive() {
        // Given
        engine.startSession()
        engine.startPause(reason: .idle, relatedApp: nil)
        let firstPauseId = engine.currentPauseEvent?.id
        XCTAssertNotNil(firstPauseId)

        // When - attempt to start a new pause without ending the first
        engine.startPause(reason: .meeting, relatedApp: "Teams")

        // Then - The first pause is ended, and currentPauseEvent becomes nil
        // It does NOT start the new pause.
        XCTAssertNil(engine.currentPauseEvent, "Current pause event should be nil after ending the previous pause")

        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1, "Should only have one pause event in session")
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.id, firstPauseId, "The recorded pause should be the first one")
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime, "The first pause should have been completed")
    }

    func testStartPauseWhenNoActiveSession() {
        // Given
        // Not starting a session
        XCTAssertNil(engine.currentSession)

        // When
        engine.startPause(reason: .systemSleep)

        // Then
        XCTAssertNotNil(engine.currentPauseEvent, "Pause event should be recorded in engine")
        XCTAssertEqual(engine.currentPauseEvent?.reason, .systemSleep)
        // Since there is no current session, it's not added to session's pause events
    }
}
