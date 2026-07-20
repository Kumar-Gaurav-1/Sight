import XCTest
@testable import Sight

final class WorkHoursManagerTests: XCTestCase {

    var testDefaults: UserDefaults!
    var prefs: PreferencesManager!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.sight.workhourstests")
        testDefaults.removePersistentDomain(forName: "com.sight.workhourstests")
        prefs = PreferencesManager.shared
        // Override with test defaults if possible, otherwise we just reset the state of the shared instance
        // Assuming PreferencesManager.shared uses standard UserDefaults, we need to reset relevant keys.
        resetPreferences()
    }

    override func tearDown() {
        resetPreferences()
        super.tearDown()
    }

    func resetPreferences() {
        prefs.quietHoursEnabled = false
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 8
        prefs.activeDays = [true, true, true, true, true, true, true]
        prefs.pauseForFullscreenApps = false
        WorkHoursManager.shared.isFullscreenAppActive = false
    }

    // MARK: - Working Hours Tests

    func testShouldPause_OutsideWorkingHours() {
        prefs.quietHoursEnabled = true

        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)

        // Set working hours such that current time is OUTSIDE them
        // If current is 14, working hours are 15 to 16
        prefs.quietHoursStart = (currentHour + 1) % 24
        prefs.quietHoursEnd = (currentHour + 2) % 24

        XCTAssertTrue(WorkHoursManager.shared.shouldPause())
        XCTAssertEqual(WorkHoursManager.shared.pauseReason, "Outside Working Hours")
    }

    func testShouldNotPause_InsideWorkingHours() {
        prefs.quietHoursEnabled = true

        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)

        // Set working hours such that current time is INSIDE them
        // If current is 14, working hours are 13 to 15
        prefs.quietHoursStart = currentHour
        prefs.quietHoursEnd = (currentHour + 2) % 24

        XCTAssertFalse(WorkHoursManager.shared.shouldPause())
        XCTAssertNil(WorkHoursManager.shared.pauseReason)
    }

    func testShouldNotPause_QuietHoursDisabled() {
        prefs.quietHoursEnabled = false

        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)

        // Set working hours such that current time is OUTSIDE them, but it shouldn't matter
        prefs.quietHoursStart = (currentHour + 1) % 24
        prefs.quietHoursEnd = (currentHour + 2) % 24

        XCTAssertFalse(WorkHoursManager.shared.shouldPause())
    }

    // MARK: - Active Days Tests

    func testShouldPause_RestDay() {
        let weekday = Calendar.current.component(.weekday, from: Date())

        var activeDays = [true, true, true, true, true, true, true]

        let index: Int
        switch weekday {
        case 1: index = 6
        case 2: index = 0
        case 3: index = 1
        case 4: index = 2
        case 5: index = 3
        case 6: index = 4
        case 7: index = 5
        default: index = 0
        }

        activeDays[index] = false
        prefs.activeDays = activeDays

        XCTAssertTrue(WorkHoursManager.shared.shouldPause())
        XCTAssertEqual(WorkHoursManager.shared.pauseReason, "Rest Day")
    }

    func testShouldNotPause_ActiveDay() {
        prefs.activeDays = [true, true, true, true, true, true, true]
        XCTAssertFalse(WorkHoursManager.shared.shouldPause())
    }

    // MARK: - Fullscreen App Tests

    func testShouldPause_FullscreenAppActive() {
        prefs.pauseForFullscreenApps = true
        WorkHoursManager.shared.isFullscreenAppActive = true

        XCTAssertTrue(WorkHoursManager.shared.shouldPause())
        XCTAssertEqual(WorkHoursManager.shared.pauseReason, "Fullscreen App")
    }

    func testShouldNotPause_FullscreenAppInactive() {
        prefs.pauseForFullscreenApps = true
        WorkHoursManager.shared.isFullscreenAppActive = false

        XCTAssertFalse(WorkHoursManager.shared.shouldPause())
    }

    func testShouldNotPause_FullscreenAppActiveButDisabledInPrefs() {
        prefs.pauseForFullscreenApps = false
        WorkHoursManager.shared.isFullscreenAppActive = true

        XCTAssertFalse(WorkHoursManager.shared.shouldPause())
    }
}
