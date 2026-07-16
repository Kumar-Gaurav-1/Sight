import XCTest
@testable import Sight

final class InsightsEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AdherenceManager.shared.resetAllStats()
    }

    override func tearDown() {
        AdherenceManager.shared.resetAllStats()
        super.tearDown()
    }

    func testGenerateInsights_EmptyState() {
        let insights = InsightsEngine.shared.generateInsights()
        XCTAssertTrue(insights.isEmpty, "Insights should be empty for a fresh state.")
    }

    func testGenerateInsights_MeetingHeavyDay() {
        AdherenceManager.shared.recordMeetingTime(minutes: 150)
        let insights = InsightsEngine.shared.generateInsights()
        XCTAssertTrue(insights.contains(.meetingHeavyDay(minutes: 150)), "Should generate meeting heavy day insight.")
    }

    func testGenerateInsights_ExcellentBlinkCompliance() {
        for _ in 0..<5 {
            AdherenceManager.shared.recordBlinkNudge(shown: true, followed: true)
        }
        let insights = InsightsEngine.shared.generateInsights()
        XCTAssertTrue(insights.contains(.excellentBlinkCompliance), "Should generate excellent blink compliance insight.")
    }

    func testGenerateInsights_PostureNeedsAttention() {
        for _ in 0..<3 {
            AdherenceManager.shared.recordPostureNudge(shown: true, followed: false)
        }
        let insights = InsightsEngine.shared.generateInsights()
        XCTAssertTrue(insights.contains(.postureNeedsAttention), "Should generate posture needs attention insight.")
    }

    func testGenerateInsights_LongStretchWarning() {
        AdherenceManager.shared.updateLongestSession(minutes: 60)
        let insights = InsightsEngine.shared.generateInsights()
        XCTAssertTrue(insights.contains(.longestStretchWarning(minutes: 60)), "Should generate longest stretch warning insight.")
    }
}
