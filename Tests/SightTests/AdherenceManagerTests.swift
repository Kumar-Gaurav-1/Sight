import XCTest
@testable import Sight

@MainActor final class AdherenceManagerTests: XCTestCase {

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

    func testRecordBreakCompletedShort() {
        adherenceManager.recordBreak(completed: true, duration: 120)
        let stats = adherenceManager.getTodayStats()

        XCTAssertEqual(stats.breaksCompleted, 1)
        XCTAssertEqual(stats.totalBreakMinutes, 2)
        XCTAssertEqual(stats.shortBreaksCompleted, 1)
        XCTAssertEqual(stats.longBreaksCompleted, 0)
        XCTAssertEqual(stats.breaksSkipped, 0)

        let hour = Calendar.current.component(.hour, from: Date())
        XCTAssertEqual(stats.hourlyBreakDistribution[hour], 1)
    }

    func testRecordBreakCompletedLong() {
        adherenceManager.recordBreak(completed: true, duration: 300)
        let stats = adherenceManager.getTodayStats()

        XCTAssertEqual(stats.breaksCompleted, 1)
        XCTAssertEqual(stats.totalBreakMinutes, 5)
        XCTAssertEqual(stats.shortBreaksCompleted, 0)
        XCTAssertEqual(stats.longBreaksCompleted, 1)
        XCTAssertEqual(stats.breaksSkipped, 0)
    }

    func testRecordBreakSkipped() {
        adherenceManager.recordBreak(completed: false, duration: 300)
        let stats = adherenceManager.getTodayStats()

        XCTAssertEqual(stats.breaksCompleted, 0)
        XCTAssertEqual(stats.totalBreakMinutes, 0)
        XCTAssertEqual(stats.shortBreaksCompleted, 0)
        XCTAssertEqual(stats.longBreaksCompleted, 0)
        XCTAssertEqual(stats.breaksSkipped, 1)
        XCTAssertEqual(adherenceManager.strainPenalty, 0.15, accuracy: 0.01)
    }
}