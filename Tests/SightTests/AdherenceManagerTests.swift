import XCTest
@testable import Sight

@MainActor
final class AdherenceManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
    }

    override func tearDown() {
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        super.tearDown()
    }

    func testRecordBreakCompletedShort() {
        let manager = AdherenceManager.shared

        manager.recordBreak(completed: true, duration: 120) // 2 minutes (<= 180s)

        let stats = manager.todayStats
        XCTAssertEqual(stats.breaksCompleted, 1)
        XCTAssertEqual(stats.totalBreakMinutes, 2)
        XCTAssertEqual(stats.shortBreaksCompleted, 1)
        XCTAssertEqual(stats.longBreaksCompleted, 0)
    }

    func testRecordBreakCompletedLong() {
        let manager = AdherenceManager.shared

        manager.recordBreak(completed: true, duration: 300) // 5 minutes (> 180s)

        let stats = manager.todayStats
        XCTAssertEqual(stats.breaksCompleted, 1)
        XCTAssertEqual(stats.totalBreakMinutes, 5)
        XCTAssertEqual(stats.shortBreaksCompleted, 0)
        XCTAssertEqual(stats.longBreaksCompleted, 1)
    }
}
