import XCTest
@testable import Sight

final class InsightsEngineTests: XCTestCase {

    var mockAdherenceManager: AdherenceManager!

    override func setUp() {
        super.setUp()
        // Create an isolated instance.
        mockAdherenceManager = AdherenceManager()
        mockAdherenceManager.resetAllStats()
    }

    override func tearDown() {
        mockAdherenceManager.resetAllStats()
        mockAdherenceManager = nil
        super.tearDown()
    }

    func testGenerateInsights_EmptyState() {
        let engine = InsightsEngine()
        let insights = engine.generateInsights(adherenceManager: mockAdherenceManager)
        XCTAssertTrue(insights.isEmpty, "Insights should be empty for a fresh state.")
    }

    func testGenerateInsights_MeetingHeavyDay() {
        mockAdherenceManager.recordMeetingTime(minutes: 150)
        let engine = InsightsEngine()
        let insights = engine.generateInsights(adherenceManager: mockAdherenceManager)
        XCTAssertTrue(insights.contains(.meetingHeavyDay(minutes: 150)), "Should generate meeting heavy day insight.")
    }

    func testGenerateInsights_ExcellentBlinkCompliance() {
        for _ in 0..<5 {
            mockAdherenceManager.recordBlinkNudge(shown: true, followed: true)
        }
        let engine = InsightsEngine()
        let insights = engine.generateInsights(adherenceManager: mockAdherenceManager)
        XCTAssertTrue(insights.contains(.excellentBlinkCompliance), "Should generate excellent blink compliance insight.")
    }

    func testGenerateInsights_PostureNeedsAttention() {
        for _ in 0..<3 {
            mockAdherenceManager.recordPostureNudge(shown: true, followed: false)
        }
        let engine = InsightsEngine()
        let insights = engine.generateInsights(adherenceManager: mockAdherenceManager)
        XCTAssertTrue(insights.contains(.postureNeedsAttention), "Should generate posture needs attention insight.")
    }

    func testGenerateInsights_LongStretchWarning() {
        mockAdherenceManager.updateLongestSession(minutes: 60)
        let engine = InsightsEngine()
        let insights = engine.generateInsights(adherenceManager: mockAdherenceManager)
        XCTAssertTrue(insights.contains(.longestStretchWarning(minutes: 60)), "Should generate longest stretch warning insight.")
    }
}
