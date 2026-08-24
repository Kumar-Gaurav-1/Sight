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

    func testRecordNudgeFollowed() {
        let manager = AdherenceManager.shared

        // Increase strain penalty first to ensure we can observe a decrease
        manager.recordNudge(action: .snoozed)
        manager.recordNudge(action: .snoozed)
        manager.recordNudge(action: .snoozed)

        let strainBeforeFollow = manager.strainPenalty
        let initialFollowed = manager.todayStats.nudgesFollowed

        manager.recordNudge(action: .followed)

        XCTAssertEqual(manager.todayStats.nudgesFollowed, initialFollowed + 1)
        XCTAssertEqual(manager.strainPenalty, max(0.0, strainBeforeFollow - 0.05))
    }

    func testRecordNudgeSnoozed() {
        let manager = AdherenceManager.shared

        let initialStrain = manager.strainPenalty
        let initialSnoozed = manager.todayStats.nudgesSnoozed

        manager.recordNudge(action: .snoozed)

        XCTAssertEqual(manager.todayStats.nudgesSnoozed, initialSnoozed + 1)
        XCTAssertEqual(manager.strainPenalty, min(1.0, initialStrain + 0.02))
    }

    func testRecordNudgeDismissed() {
        let manager = AdherenceManager.shared

        let initialSnoozed = manager.todayStats.nudgesSnoozed
        let initialStrain = manager.strainPenalty

        manager.recordNudge(action: .dismissed)

        XCTAssertEqual(manager.todayStats.nudgesSnoozed, initialSnoozed + 1)
        XCTAssertEqual(manager.strainPenalty, initialStrain) // Doesn't change
    }
}
