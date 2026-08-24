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

    func testRecordNudgeFollowed() {
        let manager = AdherenceManager.shared
        let initialNudgesFollowed = manager.todayStats.nudgesFollowed

        manager.recordNudge(action: .followed)

        XCTAssertEqual(manager.todayStats.nudgesFollowed, initialNudgesFollowed + 1)
        XCTAssertEqual(manager.strainPenalty, 0.0) // Initial is 0.0, max(0.0, 0.0 - 0.05) is 0.0
    }

    func testRecordNudgeSnoozed() {
        let manager = AdherenceManager.shared
        let initialNudgesSnoozed = manager.todayStats.nudgesSnoozed
        let initialStrainPenalty = manager.strainPenalty

        manager.recordNudge(action: .snoozed)

        XCTAssertEqual(manager.todayStats.nudgesSnoozed, initialNudgesSnoozed + 1)
        XCTAssertEqual(manager.strainPenalty, min(1.0, initialStrainPenalty + 0.02))
    }

    func testRecordNudgeDismissed() {
        let manager = AdherenceManager.shared
        let initialNudgesSnoozed = manager.todayStats.nudgesSnoozed
        let initialStrainPenalty = manager.strainPenalty

        manager.recordNudge(action: .dismissed)

        // As per current implementation, dismissed nudges are counted as snoozed
        XCTAssertEqual(manager.todayStats.nudgesSnoozed, initialNudgesSnoozed + 1)
        XCTAssertEqual(manager.strainPenalty, initialStrainPenalty) // Strain penalty remains unchanged
    }
}
