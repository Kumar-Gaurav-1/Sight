import XCTest
@testable import Sight

@MainActor
final class WorkHoursManagerTests: XCTestCase {
    private var manager: WorkHoursManager!
    private var prefs: PreferencesManager!

    // Original preferences state to restore
    private var originalQuietHoursEnabled: Bool!
    private var originalQuietHoursStart: Int!
    private var originalQuietHoursEnd: Int!
    private var originalActiveDays: [Bool]!
    private var originalPauseForFullscreenApps: Bool!

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

        // Set predictable default test state
        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17
        prefs.activeDays = [true, true, true, true, true, false, false] // Mon-Fri active
        prefs.pauseForFullscreenApps = false
    }

    override func tearDown() {
        // Restore original state
        prefs.quietHoursEnabled = originalQuietHoursEnabled
        prefs.quietHoursStart = originalQuietHoursStart
        prefs.quietHoursEnd = originalQuietHoursEnd
        prefs.activeDays = originalActiveDays
        prefs.pauseForFullscreenApps = originalPauseForFullscreenApps

        manager = nil
        prefs = nil
        super.tearDown()
    }

    private func date(year: Int = 2023, month: Int = 10, day: Int = 16, hour: Int) -> Date {
        // Oct 16, 2023 is a Monday
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)!
    }

    private func sunday(hour: Int) -> Date {
        // Oct 15, 2023 is a Sunday
        return date(year: 2023, month: 10, day: 15, hour: hour)
    }

    func testShouldPause_DisabledQuietHours_ActiveDay() {
        prefs.quietHoursEnabled = false
        // 10 PM
        let testDate = date(hour: 22)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertFalse(result)
        XCTAssertFalse(manager.shouldPauseForSchedule)
        XCTAssertNil(manager.pauseReason)
    }

    func testShouldPause_OutsideWorkingHours() {
        // 18:00 (6 PM) is outside 9-17
        let testDate = date(hour: 18)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertTrue(result)
        XCTAssertTrue(manager.shouldPauseForSchedule)
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")
    }

    func testShouldPause_InsideWorkingHours() {
        // 10:00 AM is inside 9-17
        let testDate = date(hour: 10)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertFalse(result)
        XCTAssertFalse(manager.shouldPauseForSchedule)
        XCTAssertNil(manager.pauseReason)
    }

    func testShouldPause_RestDay() {
        // Sunday
        let testDate = sunday(hour: 10)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertTrue(result)
        XCTAssertTrue(manager.shouldPauseForSchedule)
        XCTAssertEqual(manager.pauseReason, "Rest Day")
    }

    func testShouldPause_OvernightWorkingHours_Outside() {
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6

        // 10:00 AM is outside 22-6
        let testDate = date(hour: 10)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertTrue(result)
        XCTAssertTrue(manager.shouldPauseForSchedule)
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")
    }

    func testShouldPause_OvernightWorkingHours_InsideLateNight() {
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6

        // 23:00 (11 PM) is inside 22-6
        let testDate = date(hour: 23)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertFalse(result)
        XCTAssertFalse(manager.shouldPauseForSchedule)
        XCTAssertNil(manager.pauseReason)
    }

    func testShouldPause_OvernightWorkingHours_InsideEarlyMorning() {
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6

        // 3:00 AM is inside 22-6
        let testDate = date(hour: 3)

        let result = manager.shouldPause(currentDate: testDate)

        XCTAssertFalse(result)
        XCTAssertFalse(manager.shouldPauseForSchedule)
        XCTAssertNil(manager.pauseReason)
    }
}
