import XCTest
@testable import Sight

final class WorkHoursManagerTests: XCTestCase {

    var manager: WorkHoursManager!
    var prefs: PreferencesManager!

    // Original states
    var originalQuietHoursEnabled: Bool!
    var originalQuietHoursStart: Int!
    var originalQuietHoursEnd: Int!
    var originalActiveDays: [Bool]!
    var originalPauseForFullscreenApps: Bool!

    override func setUp() {
        super.setUp()
        manager = WorkHoursManager.shared
        prefs = PreferencesManager.shared

        // Save original state
        originalQuietHoursEnabled = prefs.quietHoursEnabled
        originalQuietHoursStart = prefs.quietHoursStart
        originalQuietHoursEnd = prefs.quietHoursEnd
        originalActiveDays = prefs.activeDays
        originalPauseForFullscreenApps = prefs.pauseForFullscreenApps
    }

    override func tearDown() {
        // Restore original state
        prefs.quietHoursEnabled = originalQuietHoursEnabled
        prefs.quietHoursStart = originalQuietHoursStart
        prefs.quietHoursEnd = originalQuietHoursEnd
        prefs.activeDays = originalActiveDays
        prefs.pauseForFullscreenApps = originalPauseForFullscreenApps

        // Reset date provider
        manager.currentDateProvider = { Date() }

        super.tearDown()
    }

    // Helper to create a specific date
    private func createDate(hour: Int, weekday: Int) -> Date {
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        var components = DateComponents()
        components.year = 2023
        components.month = 10
        // Find a day that matches the weekday in Oct 2023. Oct 1, 2023 is Sunday (1)
        components.day = 1 + (weekday - 1)
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)!
    }

    func testShouldPauseOutsideWorkingHoursStandard() {
        // Setup: Monday at 23:00
        manager.currentDateProvider = { self.createDate(hour: 23, weekday: 2) }

        prefs.quietHoursEnabled = true
        // Working hours: 9 to 17
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17

        // Make Monday active (index 0)
        prefs.activeDays = [true, false, false, false, false, false, false]
        prefs.pauseForFullscreenApps = false

        let shouldPause = manager.shouldPause()

        XCTAssertTrue(shouldPause)
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")
        XCTAssertTrue(manager.shouldPauseForSchedule)
    }

    func testShouldNotPauseInsideWorkingHoursStandard() {
        // Setup: Monday at 14:00
        manager.currentDateProvider = { self.createDate(hour: 14, weekday: 2) }

        prefs.quietHoursEnabled = true
        // Working hours: 9 to 17
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17

        // Make Monday active
        prefs.activeDays = [true, false, false, false, false, false, false]
        prefs.pauseForFullscreenApps = false

        let shouldPause = manager.shouldPause()

        XCTAssertFalse(shouldPause)
        XCTAssertNil(manager.pauseReason)
        XCTAssertFalse(manager.shouldPauseForSchedule)
    }

    func testShouldPauseOutsideWorkingHoursOvernight() {
        // Setup: Monday at 10:00 AM (which is outside working hours if working overnight)
        manager.currentDateProvider = { self.createDate(hour: 10, weekday: 2) }

        prefs.quietHoursEnabled = true
        // Working hours: 22 to 6 (overnight)
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6

        prefs.activeDays = [true, false, false, false, false, false, false]
        prefs.pauseForFullscreenApps = false

        let shouldPause = manager.shouldPause()

        XCTAssertTrue(shouldPause)
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")
        XCTAssertTrue(manager.shouldPauseForSchedule)
    }

    func testShouldNotPauseInsideWorkingHoursOvernight() {
        // Setup: Monday at 23:00 (which is inside working hours if working overnight)
        manager.currentDateProvider = { self.createDate(hour: 23, weekday: 2) }

        prefs.quietHoursEnabled = true
        // Working hours: 22 to 6 (overnight)
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6

        prefs.activeDays = [true, false, false, false, false, false, false]
        prefs.pauseForFullscreenApps = false

        let shouldPause = manager.shouldPause()

        XCTAssertFalse(shouldPause)
        XCTAssertNil(manager.pauseReason)
        XCTAssertFalse(manager.shouldPauseForSchedule)
    }

    func testShouldPauseOnRestDay() {
        // Setup: Sunday (weekday 1) at 12:00
        manager.currentDateProvider = { self.createDate(hour: 12, weekday: 1) }

        // Working hours are valid, so it doesn't pause for that
        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17

        // Make Sunday inactive (index 6 is Sunday)
        prefs.activeDays = [true, true, true, true, true, true, false]
        prefs.pauseForFullscreenApps = false

        let shouldPause = manager.shouldPause()

        XCTAssertTrue(shouldPause)
        XCTAssertEqual(manager.pauseReason, "Rest Day")
        XCTAssertTrue(manager.shouldPauseForSchedule)
    }

    func testQuietHoursDisabledShouldNotPauseOutsideHours() {
        // Setup: Monday at 23:00 (outside normal working hours)
        manager.currentDateProvider = { self.createDate(hour: 23, weekday: 2) }

        // Disable quiet hours
        prefs.quietHoursEnabled = false
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17

        // Monday is active
        prefs.activeDays = [true, false, false, false, false, false, false]
        prefs.pauseForFullscreenApps = false

        let shouldPause = manager.shouldPause()

        XCTAssertFalse(shouldPause)
        XCTAssertNil(manager.pauseReason)
        XCTAssertFalse(manager.shouldPauseForSchedule)
    }
}
