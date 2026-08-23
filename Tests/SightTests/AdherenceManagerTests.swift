import XCTest
@testable import Sight

@MainActor
final class AdherenceManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AdherenceManager.shared.resetAllStats()
    }

    override func tearDown() {
        AdherenceManager.shared.resetAllStats()
        super.tearDown()
    }

    func testRecordBreakCompletedShort() {
        let manager = AdherenceManager.shared

        // Set initial strain to verify reduction (max max(0.0, strainPenalty - 0.20))
        manager.recordBreak(completed: false, duration: 300)
        // strainPenalty is now 0.15

        manager.recordBreak(completed: true, duration: 120) // 2 minutes (<= 180s)

        let stats = manager.todayStats
        XCTAssertEqual(stats.breaksCompleted, 1)
        XCTAssertEqual(stats.totalBreakMinutes, 2) // max(1, 120 / 60)
        XCTAssertEqual(stats.shortBreaksCompleted, 1)
        XCTAssertEqual(stats.longBreaksCompleted, 0)

        // Initial strain was 0.15, breakReward is 0.20, so max(0.0, 0.15 - 0.20) == 0.0
        XCTAssertEqual(manager.strainPenalty, 0.0, accuracy: 0.001)
    }

    func testRecordBreakCompletedLong() {
        let manager = AdherenceManager.shared

        manager.recordBreak(completed: true, duration: 300) // 5 minutes (> 180s)

        let stats = manager.todayStats
        XCTAssertEqual(stats.breaksCompleted, 1)
        XCTAssertEqual(stats.totalBreakMinutes, 5) // max(1, 300 / 60)
        XCTAssertEqual(stats.shortBreaksCompleted, 0)
        XCTAssertEqual(stats.longBreaksCompleted, 1)
    }

    func testRecordBreakSkipped() {
        let manager = AdherenceManager.shared

        manager.recordBreak(completed: false, duration: 300)

        let stats = manager.todayStats
        XCTAssertEqual(stats.breaksCompleted, 0)
        XCTAssertEqual(stats.totalBreakMinutes, 0)
        XCTAssertEqual(stats.shortBreaksCompleted, 0)
        XCTAssertEqual(stats.longBreaksCompleted, 0)
        XCTAssertEqual(stats.breaksSkipped, 1)

        // skipCost is 0.15, so strainPenalty should increase from 0.0 to 0.15
        XCTAssertEqual(manager.strainPenalty, 0.15, accuracy: 0.001)
    }
}
