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

        // Use the singleton instance
        statisticsEngine = StatisticsEngine.shared
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
        // We can't guarantee empty because it's a singleton, but we can verify it doesn't crash
        XCTAssertNotNil(statisticsEngine)
    }

    // MARK: - Session Management Tests

    func testStartSession() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        XCTAssertNotNil(statisticsEngine.currentSession)
    }

    func testStartSessionIgnoresIfAlreadyActive() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        let firstSessionId = statisticsEngine.currentSession?.id

        statisticsEngine.startSession()
        XCTAssertEqual(statisticsEngine.currentSession?.id, firstSessionId)
    }

    func testEndSession() {
        statisticsEngine.endSession() // Clear any existing
        let initialCount = statisticsEngine.todaySessions.count

        statisticsEngine.startSession()
        statisticsEngine.endSession()

        XCTAssertNil(statisticsEngine.currentSession)
        XCTAssertEqual(statisticsEngine.todaySessions.count, initialCount + 1)
        XCTAssertFalse(statisticsEngine.todaySessions.last!.isActive)
    }

    func testRecordBreak() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.recordBreak(completed: true)

        XCTAssertEqual(statisticsEngine.currentSession?.breaksTaken, 1)
        XCTAssertEqual(statisticsEngine.currentSession?.breaksSkipped, 0)
    }

    func testRecordBreakSkipped() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.recordBreak(completed: false)

        XCTAssertEqual(statisticsEngine.currentSession?.breaksTaken, 0)
        XCTAssertEqual(statisticsEngine.currentSession?.breaksSkipped, 1)
    }

    func testRecordNudge() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.recordNudge(followed: true)

        XCTAssertEqual(statisticsEngine.currentSession?.nudgesFollowed, 1)
        XCTAssertEqual(statisticsEngine.currentSession?.nudgesDismissed, 0)
    }

    func testRecordNudgeDismissed() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.recordNudge(followed: false)

        XCTAssertEqual(statisticsEngine.currentSession?.nudgesFollowed, 0)
        XCTAssertEqual(statisticsEngine.currentSession?.nudgesDismissed, 1)
    }

    // MARK: - Pause Tracking Tests

    func testStartPause() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .idle)

        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .idle)
        XCTAssertGreaterThanOrEqual(statisticsEngine.currentSession?.pauseEvents.count ?? 0, 1)
    }

    func testStartPauseWhenAlreadyPaused() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .idle)
        let firstPauseId = statisticsEngine.currentPauseEvent?.id

        statisticsEngine.startPause(reason: .meeting)

        XCTAssertNotNil(statisticsEngine.currentPauseEvent)
        XCTAssertEqual(statisticsEngine.currentPauseEvent?.reason, .meeting)
        XCTAssertNotEqual(statisticsEngine.currentPauseEvent?.id, firstPauseId)

        XCTAssertNotNil(statisticsEngine.currentSession?.pauseEvents.first?.endTime)
    }

    func testEndPause() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()
        statisticsEngine.startPause(reason: .idle)
        statisticsEngine.endPause()

        XCTAssertNil(statisticsEngine.currentPauseEvent)
        XCTAssertNotNil(statisticsEngine.currentSession?.pauseEvents.first?.endTime)
    }

    // MARK: - Analytics Tests

    func testTodaySessionStats() {
        statisticsEngine.endSession() // Clear any existing

        let initialStats = statisticsEngine.todaySessionStats

        statisticsEngine.startSession()
        statisticsEngine.endSession()
        statisticsEngine.startSession()

        let stats = statisticsEngine.todaySessionStats
        XCTAssertEqual(stats.count, initialStats.count + 2)
        XCTAssertGreaterThanOrEqual(stats.totalActive, initialStats.totalActive)
    }

    func testTodayPauseBreakdown() {
        statisticsEngine.endSession() // Clear any existing
        statisticsEngine.startSession()

        let initialBreakdown = statisticsEngine.todayPauseBreakdown()
        let initialMeetingCount = initialBreakdown[.meeting]?.count ?? 0
        let initialIdleCount = initialBreakdown[.idle]?.count ?? 0

        statisticsEngine.startPause(reason: .meeting)
        statisticsEngine.endPause()
        statisticsEngine.startPause(reason: .idle)
        statisticsEngine.endPause()
        statisticsEngine.startPause(reason: .meeting)
        statisticsEngine.endPause()

        let breakdown = statisticsEngine.todayPauseBreakdown()

        XCTAssertEqual(breakdown[.meeting]?.count, initialMeetingCount + 2)
        XCTAssertEqual(breakdown[.idle]?.count, initialIdleCount + 1)
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
