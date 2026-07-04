import XCTest
@testable import Sight

final class AdherenceManagerTests: XCTestCase {

    var manager: AdherenceManager!

    override func setUp() {
        super.setUp()
        // Reset user defaults to prevent test pollution
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        manager = AdherenceManager()
        manager.resetAllStats()
    }

    override func tearDown() {
        manager.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        manager = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(manager.todayStats.breaksCompleted, 0)
        XCTAssertEqual(manager.weeklyScore, 100.0)
        XCTAssertEqual(manager.strainPenalty, 0.0)
        XCTAssertEqual(manager.dailyBreakGoal, 6) // Default
    }

    func testRecordBreak() {
        manager.recordBreak(completed: true, duration: 300) // 5 minutes

        XCTAssertEqual(manager.todayStats.breaksCompleted, 1)
        XCTAssertEqual(manager.todayStats.totalBreakMinutes, 5)
        XCTAssertEqual(manager.todayStats.longBreaksCompleted, 1)
        XCTAssertEqual(manager.todayStats.shortBreaksCompleted, 0)
    }

    func testRecordShortBreak() {
        manager.recordBreak(completed: true, duration: 120) // 2 minutes

        XCTAssertEqual(manager.todayStats.breaksCompleted, 1)
        XCTAssertEqual(manager.todayStats.totalBreakMinutes, 2)
        XCTAssertEqual(manager.todayStats.shortBreaksCompleted, 1)
        XCTAssertEqual(manager.todayStats.longBreaksCompleted, 0)
    }

    func testRecordBreakSkipped() {
        let initialStrain = manager.strainPenalty
        manager.recordBreak(completed: false, duration: 0)

        XCTAssertEqual(manager.todayStats.breaksSkipped, 1)
        XCTAssertGreaterThan(manager.strainPenalty, initialStrain) // Should increase
    }

    func testRecordNudge() {
        manager.recordNudge(action: .followed)
        XCTAssertEqual(manager.todayStats.nudgesFollowed, 1)
        XCTAssertEqual(manager.todayStats.nudgesSnoozed, 0)

        manager.recordNudge(action: .snoozed)
        XCTAssertEqual(manager.todayStats.nudgesFollowed, 1)
        XCTAssertEqual(manager.todayStats.nudgesSnoozed, 1)
    }

    func testEnhancedTracking() {
        manager.recordBlinkNudge(shown: true, followed: true)
        XCTAssertEqual(manager.todayStats.blinkNudgesShown, 1)
        XCTAssertEqual(manager.todayStats.blinkNudgesFollowed, 1)

        manager.recordPostureNudge(shown: true, followed: false)
        XCTAssertEqual(manager.todayStats.postureNudgesShown, 1)
        XCTAssertEqual(manager.todayStats.postureNudgesFollowed, 0)
    }

    func testTimeTracking() {
        manager.recordActiveTime(minutes: 60)
        XCTAssertEqual(manager.todayStats.totalScreenTimeMinutes, 60)

        manager.recordMeetingTime(minutes: 30)
        XCTAssertEqual(manager.todayStats.totalMeetingMinutes, 30)

        manager.recordIdleTime(minutes: 15)
        XCTAssertEqual(manager.todayStats.totalIdleMinutes, 15)

        manager.updateLongestSession(minutes: 45)
        XCTAssertEqual(manager.todayStats.longestSessionMinutes, 45)
    }

    func testScoringLogic() {
        manager.recordBreak(completed: true, duration: 300)
        manager.recordBreak(completed: false, duration: 0) // Skipped
        manager.recordNudge(action: .followed)
        manager.recordNudge(action: .snoozed)

        let dailyScore = manager.todayStats.dailyScore
        // 1 completed break, 1 followed nudge = 2 full points
        // 1 snoozed nudge = 0.5 points
        // 1 skipped break = 0 points
        // Total points = 2.5
        // Total events = 4
        // Score = (2.5 / 4) * 100 = 62.5
        XCTAssertEqual(dailyScore, 62.5, accuracy: 0.1)

        // Setup session and recovery to check wellness score
        manager.updateLongestSession(minutes: 50)
        manager.recordScreenTime(minutes: 120) // Total screen time 120, break time 5 min

        let wellnessScore = manager.todayStats.wellnessScore
        XCTAssertGreaterThan(wellnessScore, 0.0)
        XCTAssertLessThanOrEqual(wellnessScore, 100.0)
    }

    func testRecordPause() {
        manager.recordPause(reason: .meeting, duration: 1800) // 30 minutes

        XCTAssertEqual(manager.todayStats.totalMeetingMinutes, 30)
        guard let pauseSummary = manager.todayStats.pauseEvents.first(where: { $0.reason == PauseReason.meeting.rawValue }) else {
            XCTFail("Missing pause summary for meeting")
            return
        }

        XCTAssertEqual(pauseSummary.count, 1)
        XCTAssertEqual(pauseSummary.totalMinutes, 30)
    }
}
