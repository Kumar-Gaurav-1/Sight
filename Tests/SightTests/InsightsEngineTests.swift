import XCTest
@testable import Sight

final class InsightsEngineTests: XCTestCase {

    var sut: InsightsEngine!
    var adherenceManager: AdherenceManager!

    override func setUp() {
        super.setUp()
        sut = InsightsEngine.shared
        adherenceManager = AdherenceManager.shared
        adherenceManager.resetAllStats()
    }

    override func tearDown() {
        adherenceManager.resetAllStats()
        sut = nil
        adherenceManager = nil
        super.tearDown()
    }

    // MARK: - generateInsights Tests

    func testGenerateInsights_goalAchieved() {
        adherenceManager.dailyBreakGoal = 1
        adherenceManager.recordBreak(completed: true, duration: 60)

        let insights = sut.generateInsights()

        XCTAssertTrue(insights.contains(where: {
            if case .goalAchieved = $0 { return true }
            return false
        }), "Insights should contain .goalAchieved")
    }

    func testGenerateInsights_longestStretchWarning() {
        adherenceManager.updateLongestSession(minutes: 60) // Thresholds.longSessionMinutes = 45

        let insights = sut.generateInsights()

        XCTAssertTrue(insights.contains(where: {
            if case .longestStretchWarning(let minutes) = $0, minutes == 60 { return true }
            return false
        }), "Insights should contain .longestStretchWarning with 60 minutes")
    }

    func testGenerateInsights_meetingHeavyDay() {
        adherenceManager.recordMeetingTime(minutes: 150) // Thresholds.heavyMeetingMinutes = 120

        let insights = sut.generateInsights()

        XCTAssertTrue(insights.contains(where: {
            if case .meetingHeavyDay(let minutes) = $0, minutes == 150 { return true }
            return false
        }), "Insights should contain .meetingHeavyDay with 150 minutes")
    }

    func testGenerateInsights_excellentBlinkCompliance() {
        // Thresholds.excellentCompliance = 0.8
        for _ in 0..<5 { // Must be >= 5
            adherenceManager.recordBlinkNudge(shown: true, followed: true)
        }

        let insights = sut.generateInsights()

        XCTAssertTrue(insights.contains(where: {
            if case .excellentBlinkCompliance = $0 { return true }
            return false
        }), "Insights should contain .excellentBlinkCompliance")
    }

    func testGenerateInsights_postureNeedsAttention() {
        // Thresholds.poorCompliance = 0.5
        for _ in 0..<4 { // Must be >= 3
            adherenceManager.recordPostureNudge(shown: true, followed: false)
        }

        let insights = sut.generateInsights()

        XCTAssertTrue(insights.contains(where: {
            if case .postureNeedsAttention = $0 { return true }
            return false
        }), "Insights should contain .postureNeedsAttention")
    }

    func testGenerateInsights_recommendedBreakInterval_short() {
        // > 4 attempts, > 40% skip rate
        for _ in 0..<5 {
            adherenceManager.recordBreak(completed: false, duration: 0) // Skips
        }

        let insights = sut.generateInsights()

        XCTAssertTrue(insights.contains(where: {
            if case .recommendedBreakInterval(let minutes) = $0, minutes == 20 { return true }
            return false
        }), "Insights should recommend 20 minutes interval")
    }

    // MARK: - predictGoalCompletion Tests

    func testPredictGoalCompletion_alreadyAchieved() {
        adherenceManager.dailyBreakGoal = 2
        adherenceManager.recordBreak(completed: true, duration: 60)
        adherenceManager.recordBreak(completed: true, duration: 60)

        let prediction = sut.predictGoalCompletion()

        XCTAssertTrue(prediction.likely)
        XCTAssertTrue(prediction.reason.contains("already achieved"))
    }
}
