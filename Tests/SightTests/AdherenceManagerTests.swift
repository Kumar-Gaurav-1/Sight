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

        let initialFollowed = manager.todayStats.nudgesFollowed

        manager.recordNudge(action: .followed)

        XCTAssertEqual(manager.todayStats.nudgesFollowed, initialFollowed + 1)
        XCTAssertEqual(manager.strainPenalty, 0.0)
    }

    func testRecordNudgeSnoozed() {
        let manager = AdherenceManager.shared

        let initialSnoozed = manager.todayStats.nudgesSnoozed
        let initialStrain = manager.strainPenalty

        manager.recordNudge(action: .snoozed)

        XCTAssertEqual(manager.todayStats.nudgesSnoozed, initialSnoozed + 1)
        XCTAssertEqual(manager.strainPenalty, min(1.0, initialStrain + 0.02))
    }

    func testRecordNudgeDismissed() {
        let manager = AdherenceManager.shared

        let initialSnoozed = manager.todayStats.nudgesSnoozed

        manager.recordNudge(action: .dismissed)

        XCTAssertEqual(manager.todayStats.nudgesSnoozed, initialSnoozed + 1)
    }

    func testRecordNudgeStrainPenaltyBounds() {
        let manager = AdherenceManager.shared

        for _ in 0..<3 {
            manager.recordNudge(action: .snoozed)
        }
        XCTAssertEqual(manager.strainPenalty, 0.06, accuracy: 0.001)

        manager.recordNudge(action: .followed)
        XCTAssertEqual(manager.strainPenalty, 0.01, accuracy: 0.001)

        manager.recordNudge(action: .followed)
        XCTAssertEqual(manager.strainPenalty, 0.0, accuracy: 0.001)
    }
}
