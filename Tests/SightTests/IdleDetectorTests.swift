import XCTest
@testable import Sight

final class IdleDetectorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PreferencesManager.shared.resetToDefaults()
        IdleDetector.shared.stop()
        IdleDetector.shared.systemIdleTimeProvider = nil
        IdleDetector.shared.onIdlePause = nil
        IdleDetector.shared.onIdleResume = nil
        IdleDetector.shared.onIdleReset = nil
    }

    override func tearDown() {
        PreferencesManager.shared.resetToDefaults()
        IdleDetector.shared.stop()
        IdleDetector.shared.systemIdleTimeProvider = nil
        IdleDetector.shared.onIdlePause = nil
        IdleDetector.shared.onIdleResume = nil
        IdleDetector.shared.onIdleReset = nil
        super.tearDown()
    }

    func testCheckIdleTime_NotIdle() {
        let detector = IdleDetector.shared
        PreferencesManager.shared.idlePauseMinutes = 5 // 300 seconds
        PreferencesManager.shared.idleResetMinutes = 15 // 900 seconds

        var pauseCalled = false
        var resetCalled = false
        detector.onIdlePause = { pauseCalled = true }
        detector.onIdleReset = { resetCalled = true }

        detector.systemIdleTimeProvider = { 100 }

        detector.checkIdleTime()

        XCTAssertFalse(detector.isIdle)
        XCTAssertEqual(detector.idleSeconds, 100)
        XCTAssertFalse(pauseCalled)
        XCTAssertFalse(resetCalled)
    }

    func testCheckIdleTime_PauseTriggered() {
        let detector = IdleDetector.shared
        PreferencesManager.shared.idlePauseMinutes = 5 // 300 seconds
        PreferencesManager.shared.idleResetMinutes = 15 // 900 seconds

        var pauseCalled = false
        var resetCalled = false
        detector.onIdlePause = { pauseCalled = true }
        detector.onIdleReset = { resetCalled = true }

        detector.systemIdleTimeProvider = { 350 }

        detector.checkIdleTime()

        XCTAssertTrue(detector.isIdle)
        XCTAssertEqual(detector.idleSeconds, 350)
        XCTAssertTrue(pauseCalled)
        XCTAssertFalse(resetCalled)
    }

    func testCheckIdleTime_ResetTriggered() {
        let detector = IdleDetector.shared
        PreferencesManager.shared.idlePauseMinutes = 5 // 300 seconds
        PreferencesManager.shared.idleResetMinutes = 15 // 900 seconds

        var pauseCalled = false
        var resetCalled = false
        detector.onIdlePause = { pauseCalled = true }
        detector.onIdleReset = { resetCalled = true }

        detector.systemIdleTimeProvider = { 1000 }

        detector.checkIdleTime()

        XCTAssertTrue(detector.isIdle)
        XCTAssertEqual(detector.idleSeconds, 1000)
        XCTAssertFalse(pauseCalled) // Should reset directly
        XCTAssertTrue(resetCalled)
    }

    func testCheckIdleTime_ResumeTriggered() {
        let detector = IdleDetector.shared
        PreferencesManager.shared.idlePauseMinutes = 5 // 300 seconds
        PreferencesManager.shared.idleResetMinutes = 15 // 900 seconds

        detector.systemIdleTimeProvider = { 350 }
        detector.checkIdleTime()
        XCTAssertTrue(detector.isIdle) // It's paused

        var resumeCalled = false
        detector.onIdleResume = { resumeCalled = true }

        detector.systemIdleTimeProvider = { 5 } // Under 10 seconds means user is back
        detector.checkIdleTime()

        XCTAssertFalse(detector.isIdle)
        XCTAssertEqual(detector.idleSeconds, 5)
        XCTAssertTrue(resumeCalled)
    }

    func testCheckIdleTime_ResetEvenIfPauseDisabled() {
        let detector = IdleDetector.shared
        PreferencesManager.shared.idlePauseMinutes = 0 // Disabled
        PreferencesManager.shared.idleResetMinutes = 15 // 900 seconds

        var resetCalled = false
        detector.onIdleReset = { resetCalled = true }

        detector.systemIdleTimeProvider = { 1000 }
        detector.checkIdleTime()

        XCTAssertTrue(detector.isIdle)
        XCTAssertTrue(resetCalled)
    }

    func testCheckIdleTime_BothThresholdsZero() {
        let detector = IdleDetector.shared
        PreferencesManager.shared.idlePauseMinutes = 0
        PreferencesManager.shared.idleResetMinutes = 0

        var pauseCalled = false
        var resetCalled = false
        detector.onIdlePause = { pauseCalled = true }
        detector.onIdleReset = { resetCalled = true }

        detector.systemIdleTimeProvider = { 10000 } // Super long idle
        detector.checkIdleTime()

        XCTAssertFalse(detector.isIdle)
        XCTAssertFalse(pauseCalled)
        XCTAssertFalse(resetCalled)
    }

    func testCheckIdleTime_SecurityEffectiveResetThreshold() {
        let detector = IdleDetector.shared
        // Reset < Pause, which is invalid logic. System should enforce Reset >= Pause.
        PreferencesManager.shared.idlePauseMinutes = 15 // 900s
        PreferencesManager.shared.idleResetMinutes = 5 // 300s

        var pauseCalled = false
        var resetCalled = false
        detector.onIdlePause = { pauseCalled = true }
        detector.onIdleReset = { resetCalled = true }

        detector.systemIdleTimeProvider = { 400 } // > 300 but < 900. Should NOT trigger reset because effective reset is max(300, 900) = 900
        detector.checkIdleTime()

        XCTAssertFalse(detector.isIdle)
        XCTAssertFalse(pauseCalled)
        XCTAssertFalse(resetCalled)

        detector.systemIdleTimeProvider = { 1000 } // > 900
        detector.checkIdleTime()

        XCTAssertTrue(detector.isIdle)
        XCTAssertTrue(resetCalled)
    }
}
