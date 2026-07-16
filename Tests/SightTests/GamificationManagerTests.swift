import XCTest
@testable import Sight

final class GamificationManagerTests: XCTestCase {

    var gamification: GamificationManager!
    var adherence: AdherenceManager!

    override func setUp() {
        super.setUp()
        // Reset UserDefaults state
        UserDefaults.standard.removeObject(forKey: "unlockedBadges")
        UserDefaults.standard.removeObject(forKey: "totalPoints")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        // Initialize managers and ensure clean state
        adherence = AdherenceManager.shared
        adherence.resetAllStats()

        gamification = GamificationManager.shared
        gamification.resetAll()
        gamification.dateProvider = Date.init
    }

    override func tearDown() {
        adherence.resetAllStats()
        gamification.resetAll()
        gamification.dateProvider = Date.init

        UserDefaults.standard.removeObject(forKey: "unlockedBadges")
        UserDefaults.standard.removeObject(forKey: "totalPoints")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        super.tearDown()
    }

    // MARK: - Break Count Badges

    func testFirstBreakBadge() {
        XCTAssertFalse(gamification.badges.first(where: { $0.id == "first_break" })!.isUnlocked)

        adherence.recordBreak(completed: true, duration: 60)
        gamification.checkAchievements()

        XCTAssertTrue(gamification.badges.first(where: { $0.id == "first_break" })!.isUnlocked)
        XCTAssertEqual(gamification.totalPoints, 50) // 50 bonus points for badge
    }

    func testBreakCountBadges() {
        for _ in 1...9 {
            adherence.recordBreak(completed: true, duration: 60)
        }
        gamification.checkAchievements()
        XCTAssertFalse(gamification.badges.first(where: { $0.id == "breaks_10" })!.isUnlocked)

        adherence.recordBreak(completed: true, duration: 60) // 10th break
        gamification.checkAchievements()
        XCTAssertTrue(gamification.badges.first(where: { $0.id == "breaks_10" })!.isUnlocked)

        for _ in 11...50 {
            adherence.recordBreak(completed: true, duration: 60)
        }
        gamification.checkAchievements()
        XCTAssertTrue(gamification.badges.first(where: { $0.id == "breaks_50" })!.isUnlocked)

        for _ in 51...100 {
            adherence.recordBreak(completed: true, duration: 60)
        }
        gamification.checkAchievements()
        XCTAssertTrue(gamification.badges.first(where: { $0.id == "breaks_100" })!.isUnlocked)
    }

    // MARK: - Streak Badges

    func testStreakBadges() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create 30 days of 100% stats
        var mockStats: [AdherenceManager.DayStats] = []
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            var dayStat = AdherenceManager.DayStats(date: date)
            dayStat.breaksCompleted = 5
            mockStats.append(dayStat)
        }

        // Save to UserDefaults directly and force refresh adherence manager to load it and recalculate streak
        let data = try! JSONEncoder().encode(mockStats)
        UserDefaults.standard.set(data, forKey: "AdherenceStats")
        adherence.forceRefresh()

        // Wait for forceRefresh's async operation to finish if any, or just check achievements
        gamification.checkAchievements()

        XCTAssertTrue(gamification.badges.first(where: { $0.id == "streak_3" })!.isUnlocked)
        XCTAssertTrue(gamification.badges.first(where: { $0.id == "streak_7" })!.isUnlocked)
        XCTAssertTrue(gamification.badges.first(where: { $0.id == "streak_30" })!.isUnlocked)
    }

    // MARK: - Time and Behavior Badges

    func testEarlyBirdBadge() {
        // Set time to 6 AM (early bird < 7 AM)
        var components = DateComponents()
        components.hour = 6
        let earlyMorning = Calendar.current.date(from: components)!

        gamification.dateProvider = { earlyMorning }

        adherence.recordBreak(completed: true, duration: 60)
        gamification.checkAchievements()

        XCTAssertTrue(gamification.badges.first(where: { $0.id == "early_bird" })!.isUnlocked)
    }

    func testNightOwlBadge() {
        // Set time to 9:30 PM (night owl >= 21)
        var components = DateComponents()
        components.hour = 21
        components.minute = 30
        let night = Calendar.current.date(from: components)!

        gamification.dateProvider = { night }

        adherence.recordBreak(completed: true, duration: 60)
        gamification.checkAchievements()

        XCTAssertTrue(gamification.badges.first(where: { $0.id == "night_owl" })!.isUnlocked)
    }

    func testWeekendWarriorBadge() {
        // Sunday is weekday 1, Saturday is weekday 7
        // Let's set it to Sunday
        var components = DateComponents()
        components.year = 2023
        components.month = 10
        components.day = 1 // Sunday Oct 1, 2023
        let weekend = Calendar.current.date(from: components)!

        gamification.dateProvider = { weekend }

        adherence.recordBreak(completed: true, duration: 60)
        gamification.checkAchievements()

        XCTAssertTrue(gamification.badges.first(where: { $0.id == "weekend_warrior" })!.isUnlocked)
    }

    func testPerfectDayBadge() {
        // Mock stats such that dailyScore >= 100 and breaksCompleted > 0
        adherence.recordBreak(completed: true, duration: 60) // Score should be 100% since no skipped breaks

        gamification.checkAchievements()
        XCTAssertTrue(gamification.badges.first(where: { $0.id == "perfect_day" })!.isUnlocked)
    }

}
