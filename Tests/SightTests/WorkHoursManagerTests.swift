import XCTest
@testable import Sight

final class WorkHoursManagerTests: XCTestCase {

    var manager: WorkHoursManager!
    var prefs: PreferencesManager!

    override func setUp() {
        super.setUp()
        // Use standard shared instance since manager uses it internally,
        // but test state modification safely by restoring it.
        manager = WorkHoursManager.shared
        prefs = PreferencesManager.shared
    }

    override func tearDown() {
        manager = nil
        prefs = nil
        super.tearDown()
    }

    // Helper to create a specific date
    func createDate(year: Int = 2023, month: Int = 10, day: Int = 9, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        // Oct 9, 2023 is a Monday.
        return Calendar.current.date(from: components)!
    }

    func testShouldPauseWhenQuietHoursDisabled() {
        let originalQuietHoursEnabled = prefs.quietHoursEnabled
        let originalActiveDays = prefs.activeDays
        defer {
            prefs.quietHoursEnabled = originalQuietHoursEnabled
            prefs.activeDays = originalActiveDays
        }

        prefs.quietHoursEnabled = false
        // Make sure active days is all true for this test
        prefs.activeDays = [true, true, true, true, true, true, true]

        let testDate = createDate(hour: 3) // 3 AM, typically outside work hours

        let shouldPause = manager.shouldPause(currentDate: testDate)

        XCTAssertFalse(shouldPause)
        XCTAssertNil(manager.pauseReason)
        XCTAssertFalse(manager.shouldPauseForSchedule)
    }

    func testShouldPauseOutsideWorkingHoursStandard() {
        let originalQuietHoursEnabled = prefs.quietHoursEnabled
        let originalQuietHoursStart = prefs.quietHoursStart
        let originalQuietHoursEnd = prefs.quietHoursEnd
        let originalActiveDays = prefs.activeDays

        defer {
            prefs.quietHoursEnabled = originalQuietHoursEnabled
            prefs.quietHoursStart = originalQuietHoursStart
            prefs.quietHoursEnd = originalQuietHoursEnd
            prefs.activeDays = originalActiveDays
        }

        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17
        prefs.activeDays = [true, true, true, true, true, true, true]

        // 8 AM is outside 9-17
        let testDate = createDate(hour: 8)

        let shouldPause = manager.shouldPause(currentDate: testDate)

        XCTAssertTrue(shouldPause)
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")
        XCTAssertTrue(manager.shouldPauseForSchedule)
    }

    func testShouldNotPauseInsideWorkingHoursStandard() {
        let originalQuietHoursEnabled = prefs.quietHoursEnabled
        let originalQuietHoursStart = prefs.quietHoursStart
        let originalQuietHoursEnd = prefs.quietHoursEnd
        let originalActiveDays = prefs.activeDays

        defer {
            prefs.quietHoursEnabled = originalQuietHoursEnabled
            prefs.quietHoursStart = originalQuietHoursStart
            prefs.quietHoursEnd = originalQuietHoursEnd
            prefs.activeDays = originalActiveDays
        }

        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17
        prefs.activeDays = [true, true, true, true, true, true, true]

        // 10 AM is inside 9-17
        let testDate = createDate(hour: 10)

        let shouldPause = manager.shouldPause(currentDate: testDate)

        XCTAssertFalse(shouldPause)
    }

    func testShouldPauseOutsideWorkingHoursOvernight() {
        let originalQuietHoursEnabled = prefs.quietHoursEnabled
        let originalQuietHoursStart = prefs.quietHoursStart
        let originalQuietHoursEnd = prefs.quietHoursEnd
        let originalActiveDays = prefs.activeDays

        defer {
            prefs.quietHoursEnabled = originalQuietHoursEnabled
            prefs.quietHoursStart = originalQuietHoursStart
            prefs.quietHoursEnd = originalQuietHoursEnd
            prefs.activeDays = originalActiveDays
        }

        prefs.quietHoursEnabled = true
        // Work hours 22:00 to 06:00
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6
        prefs.activeDays = [true, true, true, true, true, true, true]

        // 12 PM is outside 22-6
        let testDate = createDate(hour: 12)

        let shouldPause = manager.shouldPause(currentDate: testDate)

        XCTAssertTrue(shouldPause)
    }

    func testShouldNotPauseInsideWorkingHoursOvernight() {
        let originalQuietHoursEnabled = prefs.quietHoursEnabled
        let originalQuietHoursStart = prefs.quietHoursStart
        let originalQuietHoursEnd = prefs.quietHoursEnd
        let originalActiveDays = prefs.activeDays

        defer {
            prefs.quietHoursEnabled = originalQuietHoursEnabled
            prefs.quietHoursStart = originalQuietHoursStart
            prefs.quietHoursEnd = originalQuietHoursEnd
            prefs.activeDays = originalActiveDays
        }

        prefs.quietHoursEnabled = true
        // Work hours 22:00 to 06:00
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 6
        prefs.activeDays = [true, true, true, true, true, true, true]

        // 23:00 is inside 22-6
        let testDate = createDate(hour: 23)
        let shouldPause = manager.shouldPause(currentDate: testDate)
        XCTAssertFalse(shouldPause)

        // 2:00 is inside 22-6
        let testDate2 = createDate(hour: 2)
        let shouldPause2 = manager.shouldPause(currentDate: testDate2)
        XCTAssertFalse(shouldPause2)
    }

    func testActiveDays() {
        let originalQuietHoursEnabled = prefs.quietHoursEnabled
        let originalActiveDays = prefs.activeDays

        defer {
            prefs.quietHoursEnabled = originalQuietHoursEnabled
            prefs.activeDays = originalActiveDays
        }

        prefs.quietHoursEnabled = false
        // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        // Disable Monday
        prefs.activeDays = [false, true, true, true, true, true, true]

        // Oct 9, 2023 is a Monday
        let mondayDate = createDate(year: 2023, month: 10, day: 9, hour: 12)

        let shouldPause = manager.shouldPause(currentDate: mondayDate)

        XCTAssertTrue(shouldPause)
        XCTAssertEqual(manager.pauseReason, "Rest Day")

        // Oct 10, 2023 is a Tuesday
        let tuesdayDate = createDate(year: 2023, month: 10, day: 10, hour: 12)
        let shouldPauseTuesday = manager.shouldPause(currentDate: tuesdayDate)

        XCTAssertFalse(shouldPauseTuesday)
    }
}
