import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var statisticsEngine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        // Prevent state leakage between tests
        AdherenceManager.shared.resetAllStats()

        // Initialize a clean StatisticsEngine
        statisticsEngine = StatisticsEngine()
    }

    override func tearDown() {
        statisticsEngine = nil
        AdherenceManager.shared.resetAllStats()
        super.tearDown()
    }

    func testStartPauseWithoutActiveSession() {
        // Act
        statisticsEngine.startPause(reason: .meeting, relatedApp: "us.zoom.xos")

        // Assert
        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .meeting)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.relatedApp, "us.zoom.xos")
        XCTAssertNil(statisticsEngine.currentSession)
    }

    func testStartPauseWithActiveSession() {
        // Arrange
        statisticsEngine.startSession()

        // Act
        statisticsEngine.startPause(reason: .idle, relatedApp: nil)

        // Assert
        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .idle)
        XCTAssertNil(statisticsEngine.currentPauseEvent?.relatedApp)

        XCTAssertNotNil(statisticsEngine.currentSession)
        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.count, 1)
        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.first?.reason, .idle)
    }

    func testStartPauseWhenAlreadyPaused() {
        // Arrange
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .focusMode, relatedApp: "com.apple.focus")

        let firstPauseEvent = statisticsEngine.currentPauseEvent
        XCTAssertNotNil(firstPauseEvent)
        XCTAssertNil(firstPauseEvent?.endTime)

        // Act
        statisticsEngine.startPause(reason: .meeting, relatedApp: "us.zoom.xos")

        // Assert
        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .meeting)

        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.count, 2)
        XCTAssertNotNil(statisticsEngine.currentSession?.pauseEvents.first?.endTime)
        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.first?.reason, .focusMode)
        XCTAssertNil(statisticsEngine.currentSession?.pauseEvents.last?.endTime)
        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.last?.reason, .meeting)
    }
}
