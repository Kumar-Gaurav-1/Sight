import XCTest
@testable import Sight

final class GamificationManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure clean state before each test
        GamificationManager.shared.resetAll()
        AdherenceManager.shared.resetAllStats()
    }

    override func tearDown() {
        // Ensure clean state after each test
        GamificationManager.shared.resetAll()
        AdherenceManager.shared.resetAllStats()
        super.tearDown()
    }

    // MARK: - Points and Basic Functionality Tests

    func testAddPoints() {
        let manager = GamificationManager.shared
        XCTAssertEqual(manager.totalPoints, 0, "Initial points should be 0")

        manager.addPoints(50)
        XCTAssertEqual(manager.totalPoints, 50, "Points should be 50 after adding 50")

        manager.addPoints(25)
        XCTAssertEqual(manager.totalPoints, 75, "Points should be 75 after adding another 25")
    }

    func testResetAll() {
        let manager = GamificationManager.shared
        manager.addPoints(100)

        // Temporarily unlock a badge for testing
        AdherenceManager.shared.recordBreak(completed: true, duration: 60)
        manager.checkAchievements()

        XCTAssertGreaterThan(manager.totalPoints, 0, "Points should be > 0 before reset")
        XCTAssertGreaterThan(manager.unlockedCount, 0, "Should have unlocked badges before reset")

        manager.resetAll()

        XCTAssertEqual(manager.totalPoints, 0, "Points should be 0 after reset")
        XCTAssertEqual(manager.unlockedCount, 0, "All badges should be locked after reset")
    }

    func testOnBreakCompletedAddsPoints() {
        let manager = GamificationManager.shared
        XCTAssertEqual(manager.totalPoints, 0, "Initial points should be 0")

        manager.onBreakCompleted()

        XCTAssertGreaterThanOrEqual(manager.totalPoints, 10, "Points should increase by at least 10 after a break is completed")
    }

    // MARK: - Badge Unlocking Tests

    func testUnlockFirstBreakBadge() {
        let manager = GamificationManager.shared
        let adherence = AdherenceManager.shared

        XCTAssertEqual(manager.unlockedCount, 0, "No badges should be unlocked initially")

        // Simulate taking 1 break
        adherence.recordBreak(completed: true, duration: 60)
        manager.checkAchievements()

        // Find the 'first_break' badge
        let firstBreakBadge = manager.badges.first { $0.id == "first_break" }

        XCTAssertNotNil(firstBreakBadge, "Badge 'first_break' should exist")
        XCTAssertTrue(firstBreakBadge?.isUnlocked == true, "The 'first_break' badge should be unlocked after 1 break")
        XCTAssertEqual(manager.unlockedCount, 1, "Exactly 1 badge should be unlocked")
    }

    func testUnlockBreaks10Badge() {
        let manager = GamificationManager.shared
        let adherence = AdherenceManager.shared

        XCTAssertEqual(manager.unlockedCount, 0, "No badges should be unlocked initially")

        // Simulate taking 10 breaks
        for _ in 1...10 {
            adherence.recordBreak(completed: true, duration: 60)
        }
        manager.checkAchievements()

        // Find the badges
        let firstBreakBadge = manager.badges.first { $0.id == "first_break" }
        let breaks10Badge = manager.badges.first { $0.id == "breaks_10" }

        XCTAssertNotNil(firstBreakBadge)
        XCTAssertTrue(firstBreakBadge?.isUnlocked == true, "The 'first_break' badge should be unlocked")

        XCTAssertNotNil(breaks10Badge)
        XCTAssertTrue(breaks10Badge?.isUnlocked == true, "The 'breaks_10' badge should be unlocked after 10 breaks")
    }
}
