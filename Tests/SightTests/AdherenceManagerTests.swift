import XCTest
@testable import Sight

@MainActor
final class AdherenceManagerTests: XCTestCase {

    var adherenceManager: AdherenceManager!

    override func setUp() {
        super.setUp()
        AdherenceManager.shared.resetAllStats()
        adherenceManager = AdherenceManager.shared
    }

    override func tearDown() {
        AdherenceManager.shared.resetAllStats()
        adherenceManager = nil
        super.tearDown()
    }

    func testRecordBreakCompleted() {
        let initialBreaks = adherenceManager.todayStats.breaksCompleted
        let initialMinutes = adherenceManager.todayStats.totalBreakMinutes
        let initialShortBreaks = adherenceManager.todayStats.shortBreaksCompleted
        let initialLongBreaks = adherenceManager.todayStats.longBreaksCompleted
        let hour = Calendar.current.component(.hour, from: Date())
        let initialHourlyCount = adherenceManager.todayStats.hourlyBreakDistribution[hour, default: 0]

        // Increase strain penalty to ensure reduceStrain can lower it
        adherenceManager.recordBreak(completed: false, duration: 0)

        let strainBeforeCompleted = adherenceManager.strainPenalty

        // Record a short break (120 seconds)
        adherenceManager.recordBreak(completed: true, duration: 120)

        XCTAssertEqual(adherenceManager.todayStats.breaksCompleted, initialBreaks + 1)
        XCTAssertEqual(adherenceManager.todayStats.totalBreakMinutes, initialMinutes + 2) // 120 / 60
        XCTAssertEqual(adherenceManager.todayStats.shortBreaksCompleted, initialShortBreaks + 1)
        XCTAssertEqual(adherenceManager.todayStats.longBreaksCompleted, initialLongBreaks)
        XCTAssertEqual(adherenceManager.todayStats.hourlyBreakDistribution[hour, default: 0], initialHourlyCount + 1)
        XCTAssertLessThan(adherenceManager.strainPenalty, strainBeforeCompleted)

        // Record a long break (240 seconds)
        adherenceManager.recordBreak(completed: true, duration: 240)

        XCTAssertEqual(adherenceManager.todayStats.breaksCompleted, initialBreaks + 2)
        XCTAssertEqual(adherenceManager.todayStats.totalBreakMinutes, initialMinutes + 6) // 2 + (240 / 60)
        XCTAssertEqual(adherenceManager.todayStats.shortBreaksCompleted, initialShortBreaks + 1)
        XCTAssertEqual(adherenceManager.todayStats.longBreaksCompleted, initialLongBreaks + 1)
        XCTAssertEqual(adherenceManager.todayStats.hourlyBreakDistribution[hour, default: 0], initialHourlyCount + 2)
    }

    func testRecordBreakSkipped() {
        let initialSkipped = adherenceManager.todayStats.breaksSkipped
        let initialStrain = adherenceManager.strainPenalty

        adherenceManager.recordBreak(completed: false, duration: 120)

        XCTAssertEqual(adherenceManager.todayStats.breaksSkipped, initialSkipped + 1)
        XCTAssertGreaterThan(adherenceManager.strainPenalty, initialStrain) // Should apply penalty
    }
}
