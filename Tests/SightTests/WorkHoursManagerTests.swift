import XCTest
@testable import Sight

@MainActor
final class WorkHoursManagerTests: XCTestCase {
    var manager: WorkHoursManager!

    override func setUp() {
        super.setUp()
        manager = WorkHoursManager.shared
    }

    func testShouldPauseOutsideWorkingHours() {
        let prefs = PreferencesManager.shared
        let originalEnabled = prefs.quietHoursEnabled
        let originalStart = prefs.quietHoursStart
        let originalEnd = prefs.quietHoursEnd
        defer {
            prefs.quietHoursEnabled = originalEnabled
            prefs.quietHoursStart = originalStart
            prefs.quietHoursEnd = originalEnd
        }

        prefs.quietHoursEnabled = true
        prefs.quietHoursStart = 9
        prefs.quietHoursEnd = 17

        let calendar = Calendar.current

        // 8 AM is outside working hours
        var components = DateComponents()
        components.hour = 8
        let outsideTime = calendar.date(from: components)!

        // ensure active day to avoid failing on rest day
        let originalActiveDays = prefs.activeDays
        prefs.activeDays = [true, true, true, true, true, true, true]
        defer { prefs.activeDays = originalActiveDays }

        let originalPauseForFullscreen = prefs.pauseForFullscreenApps
        prefs.pauseForFullscreenApps = false
        defer { prefs.pauseForFullscreenApps = originalPauseForFullscreen }

        XCTAssertTrue(manager.shouldPause(currentDate: outsideTime))
        XCTAssertEqual(manager.pauseReason, "Outside Working Hours")
        XCTAssertTrue(manager.shouldPauseForSchedule)

        // 10 AM is within working hours
        components.hour = 10
        let insideTime = calendar.date(from: components)!

        XCTAssertFalse(manager.shouldPause(currentDate: insideTime))
        XCTAssertNil(manager.pauseReason)
        XCTAssertFalse(manager.shouldPauseForSchedule)
    }

    func testShouldPauseOnRestDay() {
        let prefs = PreferencesManager.shared
        let originalActiveDays = prefs.activeDays
        let originalQuietHours = prefs.quietHoursEnabled
        defer {
            prefs.activeDays = originalActiveDays
            prefs.quietHoursEnabled = originalQuietHours
        }

        prefs.quietHoursEnabled = false
        prefs.activeDays = [false, false, false, false, false, false, false]

        let anyDate = Date()
        XCTAssertTrue(manager.shouldPause(currentDate: anyDate))
        XCTAssertEqual(manager.pauseReason, "Rest Day")
        XCTAssertTrue(manager.shouldPauseForSchedule)
    }
}
