import XCTest
@testable import Sight

@MainActor
final class InsightsEngineTests: XCTestCase {

    private var engine: InsightsEngine!
    private var adherence: AdherenceManager!

    override func setUp() {
        super.setUp()
        // Instantiate the singleton since we can't easily inject it into InsightsEngine without refactoring.
        // We reset it and manage its state fully for each test to avoid side effects.
        adherence = AdherenceManager.shared
        adherence.resetAllStats()

        engine = InsightsEngine.shared
    }

    override func tearDown() {
        adherence.resetAllStats()
        engine = nil
        adherence = nil
        super.tearDown()
    }

    func testGenerateInsights_EmptyData() {
        let insights = engine.generateInsights()

        XCTAssertTrue(insights.isEmpty || insights.contains(where: {
            if case .streakAchievement = $0 { return true }
            return false
        }) == false)
    }

    func testPredictGoalCompletion_AlreadyAchieved() {
        // Set up the state using the property directly to avoid initialization issues
        let originalGoal = adherence.dailyBreakGoal
        defer { adherence.dailyBreakGoal = originalGoal }

        adherence.dailyBreakGoal = 2

        adherence.recordBreak(completed: true, duration: 60)
        adherence.recordBreak(completed: true, duration: 60)

        let result = engine.predictGoalCompletion()
        XCTAssertTrue(result.likely)
        XCTAssertEqual(result.reason, "Goal already achieved! 🎉")
    }

    func testGetRecommendations_LongSession() {
        // Record longest session directly using the verified API
        adherence.updateLongestSession(minutes: 50)

        let recommendations = engine.getRecommendations()
        XCTAssertTrue(recommendations.contains("Try the Pomodoro technique: 25 min work + 5 min break"))
    }

    func testGetDetailedPatterns_EmptyData() {
        let patterns = engine.getDetailedPatterns()

        XCTAssertTrue(patterns.isEmpty)
    }
}