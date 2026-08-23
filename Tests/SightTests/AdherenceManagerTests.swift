import XCTest
@testable import Sight

@MainActor
final class AdherenceManagerTests: XCTestCase {
    var manager: AdherenceManager!

    override func setUp() {
        super.setUp()
        manager = AdherenceManager()
        manager.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
    }

    override func tearDown() {
        manager.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        manager = nil
        super.tearDown()
    }

    func testRecordBreakCompletedShort() {
        let initialStrain = manager.strainPenalty

        manager.recordBreak(completed: true, duration: 120)

        let today = manager.todayStats
        XCTAssertEqual(today.breaksCompleted, 1)
        XCTAssertEqual(today.totalBreakMinutes, 2)
        XCTAssertEqual(today.shortBreaksCompleted, 1)
        XCTAssertEqual(today.longBreaksCompleted, 0)

        let hour = Calendar.current.component(.hour, from: Date())
        XCTAssertEqual(today.hourlyBreakDistribution[hour], 1)

        XCTAssertTrue(manager.strainPenalty <= initialStrain)
    }

    func testRecordBreakCompletedLong() {
        manager.recordBreak(completed: true, duration: 300)

        let today = manager.todayStats
        XCTAssertEqual(today.breaksCompleted, 1)
        XCTAssertEqual(today.totalBreakMinutes, 5)
        XCTAssertEqual(today.shortBreaksCompleted, 0)
        XCTAssertEqual(today.longBreaksCompleted, 1)
    }

    func testRecordBreakSkipped() {
        let initialStrain = manager.strainPenalty

        manager.recordBreak(completed: false, duration: 120)

        let today = manager.todayStats
        XCTAssertEqual(today.breaksSkipped, 1)
        XCTAssertEqual(today.breaksCompleted, 0)

        XCTAssertTrue(manager.strainPenalty >= initialStrain)
    }
}
