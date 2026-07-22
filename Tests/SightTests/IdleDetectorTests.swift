import XCTest
import Combine
@testable import Sight

final class IdleDetectorTests: XCTestCase {

    var idleDetector: IdleDetector!
    var originalSystemIdleTimeProvider: (() -> Int)!
    var originalPauseMinutes: Int!
    var originalResetMinutes: Int!

    override func setUp() {
        super.setUp()
        idleDetector = IdleDetector.shared
        idleDetector.stop() // reset state

        originalSystemIdleTimeProvider = idleDetector.systemIdleTimeProvider

        // Save original preferences
        originalPauseMinutes = PreferencesManager.shared.idlePauseMinutes
        originalResetMinutes = PreferencesManager.shared.idleResetMinutes
    }

    override func tearDown() {
        idleDetector.stop()
        idleDetector.onIdlePause = nil
        idleDetector.onIdleResume = nil
        idleDetector.onIdleReset = nil

        // Restore default provider
        idleDetector.systemIdleTimeProvider = originalSystemIdleTimeProvider

        // Restore preferences
        PreferencesManager.shared.idlePauseMinutes = originalPauseMinutes
        PreferencesManager.shared.idleResetMinutes = originalResetMinutes

        super.tearDown()
    }

    func testIdlePauseTrigger() {
        PreferencesManager.shared.idlePauseMinutes = 1 // 60 seconds
        PreferencesManager.shared.idleResetMinutes = 5 // 300 seconds

        let expectationPause = XCTestExpectation(description: "Pause triggered")
        idleDetector.onIdlePause = { expectationPause.fulfill() }

        idleDetector.systemIdleTimeProvider = { return 65 }
        idleDetector.checkIdleTime()

        wait(for: [expectationPause], timeout: 1.0)
        XCTAssertTrue(idleDetector.isIdle)
    }

    func testIdleResetTrigger() {
        PreferencesManager.shared.idlePauseMinutes = 1
        PreferencesManager.shared.idleResetMinutes = 5

        let expectationReset = XCTestExpectation(description: "Reset triggered")
        idleDetector.onIdleReset = { expectationReset.fulfill() }

        idleDetector.systemIdleTimeProvider = { return 305 }
        idleDetector.checkIdleTime()

        wait(for: [expectationReset], timeout: 1.0)
        XCTAssertTrue(idleDetector.isIdle)
    }

    func testIdleResumeTrigger() {
        PreferencesManager.shared.idlePauseMinutes = 1
        PreferencesManager.shared.idleResetMinutes = 5

        // First trigger idle
        idleDetector.systemIdleTimeProvider = { return 65 }
        idleDetector.checkIdleTime()
        XCTAssertTrue(idleDetector.isIdle)

        // Now user comes back
        let expectationResume = XCTestExpectation(description: "Resume triggered")
        idleDetector.onIdleResume = { expectationResume.fulfill() }

        idleDetector.systemIdleTimeProvider = { return 5 }
        idleDetector.checkIdleTime()

        wait(for: [expectationResume], timeout: 1.0)
        XCTAssertFalse(idleDetector.isIdle)
    }

    func testDisablePauseFeature() {
        PreferencesManager.shared.idlePauseMinutes = 0 // disabled
        PreferencesManager.shared.idleResetMinutes = 5

        let expectationPause = XCTestExpectation(description: "Pause triggered")
        expectationPause.isInverted = true
        idleDetector.onIdlePause = { expectationPause.fulfill() }

        idleDetector.systemIdleTimeProvider = { return 65 }
        idleDetector.checkIdleTime()

        wait(for: [expectationPause], timeout: 1.0)
        XCTAssertFalse(idleDetector.isIdle) // Should not be idle at 65s if pause disabled
    }
}
