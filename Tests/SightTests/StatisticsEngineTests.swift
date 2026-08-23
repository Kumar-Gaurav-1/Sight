import XCTest
@testable import Sight

@MainActor final class StatisticsEngineTests: XCTestCase {

    var engine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Use the shared instance but clear its state for testing
        engine = StatisticsEngine.shared

        // Clean up AdherenceManager state to prevent state leakage
        AdherenceManager.shared.resetAllStats()

        // Clean up any existing state before starting
        if engine.currentSession != nil {
            engine.endSession()
        }
        if engine.currentPauseEvent != nil {
            engine.endPause()
        }

        // Ensure starting from a clean slate
        XCTAssertNil(engine.currentSession)
        XCTAssertNil(engine.currentPauseEvent)
    }

    override func tearDown() {
        if engine.currentPauseEvent != nil {
            engine.endPause()
        }
        if engine.currentSession != nil {
            engine.endSession()
        }

        // Clean up AdherenceManager state to prevent state leakage
        AdherenceManager.shared.resetAllStats()

        engine = nil
        super.tearDown()
    }

    func testStartPauseSuccess() {
        // Arrange
        engine.startSession()
        XCTAssertNotNil(engine.currentSession, "Session should be started")

        // Act
        engine.startPause(reason: .meeting, relatedApp: "zoom")

        // Assert
        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(engine.currentPauseEvent?.relatedApp, "zoom")
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.reason, .meeting)
    }

    func testStartPauseWhenAlreadyPaused() {
        // Arrange
        engine.startSession()
        engine.startPause(reason: .meeting, relatedApp: "zoom")
        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .meeting)

        let firstPauseEventId = engine.currentPauseEvent?.id

        // Act - try to start another pause
        engine.startPause(reason: .focusMode, relatedApp: nil)

        // Assert - The second pause start should fail and trigger an endPause on the first one
        XCTAssertNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentSession?.pauseEvents.count, 1)
        XCTAssertEqual(engine.currentSession?.pauseEvents.first?.id, firstPauseEventId)

        // Ensure the pause event in the session has an end time
        XCTAssertNotNil(engine.currentSession?.pauseEvents.first?.endTime)
    }

    func testStartPauseWithoutActiveSession() {
        // Arrange - No active session (setUp ensures this)

        // Act
        engine.startPause(reason: .idle, relatedApp: nil)

        // Assert
        XCTAssertNotNil(engine.currentPauseEvent)
        XCTAssertEqual(engine.currentPauseEvent?.reason, .idle)
        XCTAssertNil(engine.currentSession)
    }
}
