import XCTest
@testable import Sight

final class InsightsEngineTests: XCTestCase {

    var engine: InsightsEngine!
    var adherenceManager: AdherenceManager!

    override func setUp() {
        super.setUp()
        engine = InsightsEngine.shared
        adherenceManager = AdherenceManager.shared

        // Reset state before each test
        adherenceManager.resetAllStats()
    }

    override func tearDown() {
        // Reset state after each test
        adherenceManager.resetAllStats()
        super.tearDown()
    }

    // MARK: - Nudge Compliance Tests

    func testGenerateInsights_ExcellentBlinkCompliance() {
        // Given
        for _ in 0..<5 {
            adherenceManager.recordBlinkNudge(shown: true, followed: true)
        }

        // When
        let insights = engine.generateInsights()

        // Then
        XCTAssertTrue(insights.contains(.excellentBlinkCompliance), "Expected excellent blink compliance insight")
    }

    func testGenerateInsights_PoorPostureCompliance() {
        // Given
        for _ in 0..<3 {
            adherenceManager.recordPostureNudge(shown: true, followed: false) // 0% compliance
        }

        // When
        let insights = engine.generateInsights()

        // Then
        XCTAssertTrue(insights.contains(.postureNeedsAttention), "Expected posture needs attention insight")
    }

    // MARK: - Session Balance & Meeting Load Tests

    func testGenerateInsights_LongSessionWarning() {
        // Given
        adherenceManager.updateLongestSession(minutes: 45) // Thresholds.longSessionMinutes is 45

        // When
        let insights = engine.generateInsights()

        // Then
        XCTAssertTrue(insights.contains(.longestStretchWarning(minutes: 45)), "Expected longest stretch warning insight")
    }

    func testGenerateInsights_MeetingHeavyDay() {
        // Given
        adherenceManager.recordMeetingTime(minutes: 120) // Thresholds.heavyMeetingMinutes is 120

        // When
        let insights = engine.generateInsights()

        // Then
        XCTAssertTrue(insights.contains(.meetingHeavyDay(minutes: 120)), "Expected meeting heavy day insight")
    }

    // MARK: - Recommend Break Interval Tests

    func testGenerateInsights_RecommendShorterBreakInterval() {
        // Given
        // totalAttempts >= 4, skipRate >= 0.4
        for _ in 0..<3 {
            adherenceManager.recordBreak(completed: false, duration: 0) // 3 skips
        }
        for _ in 0..<2 {
            adherenceManager.recordBreak(completed: true, duration: 300) // 2 completions
        }

        // When
        let insights = engine.generateInsights()

        // Then
        XCTAssertTrue(insights.contains(.recommendedBreakInterval(minutes: 20)), "Expected recommended shorter break interval insight")
    }

    // MARK: - Predict Goal Completion Tests

    func testPredictGoalCompletion_GoalAchieved() {
        // Given
        let goal = adherenceManager.dailyBreakGoal
        for _ in 0..<goal {
            adherenceManager.recordBreak(completed: true, duration: 300)
        }

        // When
        let prediction = engine.predictGoalCompletion()

        // Then
        XCTAssertTrue(prediction.likely)
        XCTAssertEqual(prediction.reason, "Goal already achieved! 🎉")
    }
}
