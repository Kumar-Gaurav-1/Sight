import XCTest
@testable import Sight

@MainActor
final class WorkHoursManagerTests: XCTestCase {
    var preferences: PreferencesManager!
    var workHoursManager: WorkHoursManager!

    override func setUp() {
        super.setUp()
        preferences = PreferencesManager.shared
        preferences.resetToDefaults()
        workHoursManager = WorkHoursManager.shared
        workHoursManager.dateProvider = Date.init
    }

    override func tearDown() {
        preferences.resetToDefaults()
        workHoursManager.dateProvider = Date.init
        super.tearDown()
    }

    private func setMockDate(hour: Int, weekday: Int) {
        var components = DateComponents()
        components.year = 2023
        components.month = 1
        // 2023-01-01 was a Sunday. Weekday: 1 = Sunday, 2 = Monday, etc.
        let offset = weekday - 1
        components.day = 1 + offset
        components.hour = hour
        components.minute = 0
        components.second = 0

        let calendar = Calendar.current
        let date = calendar.date(from: components)!
        workHoursManager.dateProvider = { date }
    }

    func testShouldPause_OutsideWorkingHours() {
        preferences.quietHoursEnabled = true
        preferences.quietHoursStart = 9
        preferences.quietHoursEnd = 17

        setMockDate(hour: 12, weekday: 2) // Monday 12 PM
        preferences.activeDays = [true, true, true, true, true, true, true]
        XCTAssertFalse(workHoursManager.shouldPause())

        setMockDate(hour: 8, weekday: 2) // Monday 8 AM
        XCTAssertTrue(workHoursManager.shouldPause())
        XCTAssertEqual(workHoursManager.pauseReason, "Outside Working Hours")
        XCTAssertTrue(workHoursManager.shouldPauseForSchedule)
    }

    func testShouldPause_OutsideWorkingHoursOvernight() {
        preferences.quietHoursEnabled = true
        preferences.quietHoursStart = 22
        preferences.quietHoursEnd = 6
        preferences.activeDays = [true, true, true, true, true, true, true]

        setMockDate(hour: 23, weekday: 2)
        XCTAssertFalse(workHoursManager.shouldPause())

        setMockDate(hour: 12, weekday: 2)
        XCTAssertTrue(workHoursManager.shouldPause())
        XCTAssertEqual(workHoursManager.pauseReason, "Outside Working Hours")
    }

    func testShouldPause_RestDay() {
        preferences.quietHoursEnabled = false
        preferences.activeDays = [true, true, true, true, true, false, false]

        setMockDate(hour: 12, weekday: 2)
        XCTAssertFalse(workHoursManager.shouldPause())

        setMockDate(hour: 12, weekday: 7)
        XCTAssertTrue(workHoursManager.shouldPause())
        XCTAssertEqual(workHoursManager.pauseReason, "Rest Day")
        XCTAssertTrue(workHoursManager.shouldPauseForSchedule)
    }

    func testShouldPause_NoPauseConditions() {
        preferences.quietHoursEnabled = true
        preferences.quietHoursStart = 9
        preferences.quietHoursEnd = 17
        preferences.activeDays = [true, true, true, true, true, true, true]

        setMockDate(hour: 12, weekday: 2)

        let result = workHoursManager.shouldPause()

        XCTAssertFalse(result)
        // isFullscreenAppActive is false by default since it only sets to true internally, and we don't mock it to true here.
    }
}
