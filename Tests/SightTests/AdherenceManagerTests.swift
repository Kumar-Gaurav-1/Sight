import XCTest
@testable import Sight

@MainActor final class AdherenceManagerTests: XCTestCase {

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
        let initialBreaks = manager.todayStats.breaksCompleted
        let initialShortBreaks = manager.todayStats.shortBreaksCompleted
        let initialMinutes = manager.todayStats.totalBreakMinutes

        manager.recordBreak(completed: true, duration: 120)

        XCTAssertEqual(manager.todayStats.breaksCompleted, initialBreaks + 1)
        XCTAssertEqual(manager.todayStats.shortBreaksCompleted, initialShortBreaks + 1)
        XCTAssertEqual(manager.todayStats.totalBreakMinutes, initialMinutes + max(1, 120 / 60))
    }

    func testRecordBreakCompletedLong() {
        let manager = AdherenceManager.shared
        let initialBreaks = manager.todayStats.breaksCompleted
        let initialLongBreaks = manager.todayStats.longBreaksCompleted
        let initialMinutes = manager.todayStats.totalBreakMinutes

        manager.recordBreak(completed: true, duration: 300)

        XCTAssertEqual(manager.todayStats.breaksCompleted, initialBreaks + 1)
        XCTAssertEqual(manager.todayStats.longBreaksCompleted, initialLongBreaks + 1)
        XCTAssertEqual(manager.todayStats.totalBreakMinutes, initialMinutes + max(1, 300 / 60))
    }
}
