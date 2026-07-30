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

    // Helper to create a specific date
    private func date(hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)!
    }

    func testPredictGoalCompletion_alreadyAchieved() {
        let adherence = AdherenceManager.shared
        let initialGoal = adherence.dailyBreakGoal
        defer { adherence.dailyBreakGoal = initialGoal }
        adherence.dailyBreakGoal = 5

        for _ in 0..<5 {
            adherence.recordBreak(completed: true, duration: 300)
        }

        let prediction = InsightsEngine.shared.predictGoalCompletion()
        XCTAssertTrue(prediction.likely)
        XCTAssertEqual(prediction.reason, "Goal already achieved! 🎉")
    }

    func testPredictGoalCompletion_morning() {
        let prediction = InsightsEngine.shared.predictGoalCompletion(currentDate: date(hour: 9))
        XCTAssertTrue(prediction.likely)
        XCTAssertEqual(prediction.reason, "Full day ahead")
    }

    func testPredictGoalCompletion_afternoon() {
        let prediction = InsightsEngine.shared.predictGoalCompletion(currentDate: date(hour: 14))
        XCTAssertTrue(prediction.likely)
        XCTAssertEqual(prediction.reason, "On track for afternoon progress")
    }

    func testPredictGoalCompletion_evening_likely() {
        let adherence = AdherenceManager.shared
        let initialGoal = adherence.dailyBreakGoal
        defer { adherence.dailyBreakGoal = initialGoal }
        adherence.dailyBreakGoal = 5

        for _ in 0..<2 {
            adherence.recordBreak(completed: true, duration: 300)
        }

        let prediction = InsightsEngine.shared.predictGoalCompletion(currentDate: date(hour: 19))
        XCTAssertTrue(prediction.likely)
        XCTAssertEqual(prediction.reason, "Evening push needed")
    }

    func testPredictGoalCompletion_evening_unlikely() {
        let adherence = AdherenceManager.shared
        let initialGoal = adherence.dailyBreakGoal
        defer { adherence.dailyBreakGoal = initialGoal }
        adherence.dailyBreakGoal = 5

        for _ in 0..<1 {
            adherence.recordBreak(completed: true, duration: 300)
        }

        let prediction = InsightsEngine.shared.predictGoalCompletion(currentDate: date(hour: 20))
        XCTAssertFalse(prediction.likely)
        XCTAssertEqual(prediction.reason, "Evening push needed")
    }

    func testPredictGoalCompletion_lateNight_almostThere() {
        let adherence = AdherenceManager.shared
        let initialGoal = adherence.dailyBreakGoal
        defer { adherence.dailyBreakGoal = initialGoal }
        adherence.dailyBreakGoal = 5

        for _ in 0..<4 {
            adherence.recordBreak(completed: true, duration: 300)
        }

        let prediction = InsightsEngine.shared.predictGoalCompletion(currentDate: date(hour: 22))
        XCTAssertTrue(prediction.likely)
        XCTAssertEqual(prediction.reason, "Almost there!")
    }

    func testPredictGoalCompletion_lateNight_runningShort() {
        let adherence = AdherenceManager.shared
        let initialGoal = adherence.dailyBreakGoal
        defer { adherence.dailyBreakGoal = initialGoal }
        adherence.dailyBreakGoal = 5

        for _ in 0..<3 {
            adherence.recordBreak(completed: true, duration: 300)
        }

        let prediction = InsightsEngine.shared.predictGoalCompletion(currentDate: date(hour: 23))
        XCTAssertFalse(prediction.likely)
        XCTAssertEqual(prediction.reason, "Time is running short")
    }
}
