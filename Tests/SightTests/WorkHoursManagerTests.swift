import XCTest
@testable import Sight

@MainActor
final class WorkHoursManagerTests: XCTestCase {

    private var originalQuietHoursEnabled: Bool!
    private var originalQuietHoursStart: Int!
    private var originalQuietHoursEnd: Int!
    private var originalActiveDays: [Bool]!

    override func setUp() {
        super.setUp()
        let prefs = PreferencesManager.shared
        originalQuietHoursEnabled = prefs.quietHoursEnabled
        originalQuietHoursStart = prefs.quietHoursStart
        originalQuietHoursEnd = prefs.quietHoursEnd
        originalActiveDays = prefs.activeDays
    }

    override func tearDown() {
        let prefs = PreferencesManager.shared
        prefs.quietHoursEnabled = originalQuietHoursEnabled
        prefs.quietHoursStart = originalQuietHoursStart
        prefs.quietHoursEnd = originalQuietHoursEnd
        prefs.activeDays = originalActiveDays
        super.tearDown()
    }

    private func createDate(weekday: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.year = 2023
        components.month = 10
        let baseDay = 1 // 2023-10-01 is Sunday (weekday 1)
        components.day = baseDay + (weekday - 1)
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    func testShouldPauseWhenOutsideStandardWorkingHours() {
        let prefs = PreferencesManager.shared
        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17
        prefs.activeDays = [true, true, true, true, true, true, true]

        let manager = WorkHoursManager.shared

        let beforeWork = createDate(weekday: 2, hour: 8) // Monday 8 AM
        XCTAssertTrue(manager.shouldPause(currentDate: beforeWork))
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")

        let afterWork = createDate(weekday: 2, hour: 18) // Monday 6 PM
        XCTAssertTrue(manager.shouldPause(currentDate: afterWork))
    }

    func testShouldNotPauseWhenInsideStandardWorkingHours() {
        let prefs = PreferencesManager.shared
        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17
        prefs.activeDays = [true, true, true, true, true, true, true]

        let manager = WorkHoursManager.shared

        let duringWork = createDate(weekday: 2, hour: 10) // 10 AM
        XCTAssertFalse(manager.shouldPause(currentDate: duringWork))
    }

    func testOvernightWorkingHours() {
        let prefs = PreferencesManager.shared
        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 22 // 10 PM
        prefs.quietHoursEnd = 6    // 6 AM
        prefs.activeDays = [true, true, true, true, true, true, true]

        let manager = WorkHoursManager.shared

        let lateNight = createDate(weekday: 2, hour: 23) // 11 PM
        XCTAssertFalse(manager.shouldPause(currentDate: lateNight))

        let earlyMorning = createDate(weekday: 2, hour: 2) // 2 AM
        XCTAssertFalse(manager.shouldPause(currentDate: earlyMorning))

        let daytime = createDate(weekday: 2, hour: 10) // 10 AM
        XCTAssertTrue(manager.shouldPause(currentDate: daytime))
    }

    func testRestDays() {
        let prefs = PreferencesManager.shared
        prefs.quietHoursEnabled = false
        prefs.activeDays = [true, true, true, true, true, false, false] // Sat/Sun off

        let manager = WorkHoursManager.shared

        let sunday = createDate(weekday: 1, hour: 12)
        XCTAssertTrue(manager.shouldPause(currentDate: sunday))
        XCTAssertEqual(manager.pauseReason, "Rest Day")

        let monday = createDate(weekday: 2, hour: 12)
        XCTAssertFalse(manager.shouldPause(currentDate: monday))
    }
}
