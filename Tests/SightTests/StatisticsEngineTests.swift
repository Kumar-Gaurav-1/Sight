import XCTest
@testable import Sight

@MainActor
final class StatisticsEngineTests: XCTestCase {

    var statisticsEngine: StatisticsEngine!

    override func setUp() {
        super.setUp()
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")

        statisticsEngine = StatisticsEngine()
    }

    override func tearDown() {
        statisticsEngine = nil
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
        UserDefaults.standard.removeObject(forKey: "SessionsDate")
        UserDefaults.standard.removeObject(forKey: "StatsLastResetDate")
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(statisticsEngine.currentSession)
        XCTAssertTrue(statisticsEngine.todaySessions.isEmpty)
        XCTAssertNil(statisticsEngine.currentPauseEvent)
        XCTAssertTrue(statisticsEngine.insights.isEmpty)
    }

    // MARK: - Session Management Tests

    func testStartSession() {
        statisticsEngine.startSession()
        XCTAssertNotNil(statisticsEngine.currentSession)
        XCTAssertEqual(statisticsEngine.todaySessions.count, 0)
    }

    func testStartSessionIgnoresIfAlreadyActive() {
        statisticsEngine.startSession()
        let firstSessionId = statisticsEngine.currentSession?.id

        statisticsEngine.startSession()
        XCTAssertEqual(statisticsEngine.currentSession?.id, firstSessionId)
    }

    func testEndSession() {
        statisticsEngine.startSession()
        statisticsEngine.endSession()

        XCTAssertNil(statisticsEngine.currentSession)
        XCTAssertEqual(statisticsEngine.todaySessions.count, 1)
        XCTAssertFalse(statisticsEngine.todaySessions.first!.isActive)
    }

    func testEndSessionWithoutActiveSession() {
        statisticsEngine.endSession()
        XCTAssertNil(statisticsEngine.currentSession)
        XCTAssertTrue(statisticsEngine.todaySessions.isEmpty)
    }

    func testRecordBreak() {
        statisticsEngine.startSession()
        statisticsEngine.recordBreak(completed: true)

        XCTAssertEqual(statisticsEngine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(statisticsEngine.currentSession?.breaksSkipped, 0)
    }

    func testRecordBreakSkipped() {
        statisticsEngine.startSession()
        statisticsEngine.recordBreak(completed: false)

        XCTAssertEqual(statisticsEngine.currentSession?.breaksTaken, 0)
        XCTAssertEqual(statisticsEngine.currentSession?.breaksSkipped, 1)
    }

    func testRecordNudge() {
        statisticsEngine.startSession()
        statisticsEngine.recordNudge(followed: true)

        XCTAssertEqual(statisticsEngine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(statisticsEngine.currentSession?.nudgesDismissed, 0)
    }

    func testRecordNudgeDismissed() {
        statisticsEngine.startSession()
        statisticsEngine.recordNudge(followed: false)

        XCTAssertEqual(statisticsEngine.currentSession?.nudgesFollowed, 0)
        XCTAssertEqual(statisticsEngine.currentSession?.nudgesDismissed, 1)
    }

    // MARK: - Pause Tracking Tests

    func testStartPause() {
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .idle)

        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .idle)
        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.count, 1)
    }

    func testStartPauseWhenAlreadyPaused() {
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .idle)
        let firstPauseId = statisticsEngine.currentPauseEvent?.id

        statisticsEngine.startPause(reason: .meeting)

        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .meeting)
        XCTAssertNotEqual(statisticsEngine.currentPauseEvent?.id, firstPauseId)

        XCTAssertEqual(statisticsEngine.currentSession?.pauseEvents.count, 2)
        XCTAssertNotNil(statisticsEngine.currentSession?.pauseEvents.first?.endTime)
    }

    func testEndPause() {
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .idle)
        statisticsEngine.endPause()

        XCTAssertNil(statisticsEngine.currentPauseEvent)
        XCTAssertNotNil(statisticsEngine.currentSession?.pauseEvents.first?.endTime)
    }

    // MARK: - Analytics Tests

    func testTodaySessionStats() {
        statisticsEngine.startSession()
        statisticsEngine.endSession()
        statisticsEngine.startSession()

        let stats = statisticsEngine.todaySessionStats
        XCTAssertEqual(stats.count, 2)
        XCTAssertGreaterThanOrEqual(stats.totalActive, 0)
    }

    func testTodayPauseBreakdown() {
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .meeting)
        statisticsEngine.endPause()
        statisticsEngine.startPause(reason: .idle)
        statisticsEngine.endPause()
        statisticsEngine.startPause(reason: .meeting)
        statisticsEngine.endPause()

        let breakdown = statisticsEngine.todayPauseBreakdown()

        XCTAssertEqual(breakdown[.meeting]?.count, 2)
        XCTAssertEqual(breakdown[.idle]?.count, 1)
    }

    func testGenerateInsights() {
        AdherenceManager.shared.recordMeetingTime(minutes: 130)
        statisticsEngine.generateInsights()

        let insights = statisticsEngine.insights
        XCTAssertTrue(insights.contains(where: {
            if case .meetingHeavyDay = $0 { return true }
            return false
        }))
    }
}
