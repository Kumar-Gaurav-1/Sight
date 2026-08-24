import XCTest
@testable import Sight

@MainActor
final class GamificationManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset AdherenceManager to prevent state leakage
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        // Reset GamificationManager
        UserDefaults.standard.removeObject(forKey: "unlockedBadges")
        UserDefaults.standard.removeObject(forKey: "totalPoints")
        GamificationManager.shared.resetAll()
    }

    override func tearDown() {
        // Reset AdherenceManager to prevent state leakage
        AdherenceManager.shared.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        // Reset GamificationManager
        UserDefaults.standard.removeObject(forKey: "unlockedBadges")
        UserDefaults.standard.removeObject(forKey: "totalPoints")
        GamificationManager.shared.resetAll()

        super.tearDown()
    }

    func testInitialState() {
        let manager = GamificationManager.shared
        XCTAssertEqual(manager.totalPoints, 0)
        XCTAssertEqual(manager.unlockedCount, 0)
        XCTAssertNil(manager.newlyUnlockedBadge)
        XCTAssertFalse(manager.badges.isEmpty)
    }

    func testAddPoints() {
        let manager = GamificationManager.shared
        XCTAssertEqual(manager.totalPoints, 0)

        manager.addPoints(50)
        XCTAssertEqual(manager.totalPoints, 50)

        manager.addPoints(25)
        XCTAssertEqual(manager.totalPoints, 75)
    }

    func testOnBreakCompletedAddsPointsAndUnlocksFirstBadge() {
        let manager = GamificationManager.shared

        XCTAssertEqual(manager.unlockedCount, 0)

        // Record a break in AdherenceManager
        AdherenceManager.shared.recordBreak(completed: true, duration: 60)

        // Call GamificationManager
        manager.onBreakCompleted()

        // Points should be 10 (base) + 50 (badge unlock bonus) = 60
        XCTAssertEqual(manager.totalPoints, 60)

        // Verify badge was unlocked
        let firstBreakBadge = manager.badges.first { $0.id == "first_break" }
        XCTAssertTrue(firstBreakBadge?.isUnlocked ?? false)
        XCTAssertEqual(manager.unlockedCount, 1)

        // Check newlyUnlockedBadge
        XCTAssertEqual(manager.newlyUnlockedBadge?.id, "first_break")
    }

    func testMultipleBreaksUnlockMilestoneBadges() {
        let manager = GamificationManager.shared

        // Complete 10 breaks
        for _ in 1...10 {
            AdherenceManager.shared.recordBreak(completed: true, duration: 60)
        }

        manager.checkAchievements()

        let tenBreaksBadge = manager.badges.first { $0.id == "breaks_10" }
        XCTAssertTrue(tenBreaksBadge?.isUnlocked ?? false)
    }

    func testPersistence() {
        let manager = GamificationManager.shared

        manager.addPoints(123)
        AdherenceManager.shared.recordBreak(completed: true, duration: 60)
        manager.checkAchievements()

        // Verify UserDefaults has values
        let points = UserDefaults.standard.integer(forKey: "totalPoints")
        XCTAssertEqual(points, 123 + 50) // 123 + 50 bonus

        let badgesData = UserDefaults.standard.data(forKey: "unlockedBadges")
        XCTAssertNotNil(badgesData)
    }

    func testResetAll() {
        let manager = GamificationManager.shared
        manager.addPoints(100)
        AdherenceManager.shared.recordBreak(completed: true, duration: 60)
        manager.checkAchievements()

        XCTAssertGreaterThan(manager.totalPoints, 0)
        XCTAssertGreaterThan(manager.unlockedCount, 0)

        manager.resetAll()

        XCTAssertEqual(manager.totalPoints, 0)
        XCTAssertEqual(manager.unlockedCount, 0)
        XCTAssertNil(manager.newlyUnlockedBadge)
    }
}