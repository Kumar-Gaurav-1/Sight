import XCTest
import Combine
@testable import Sight

final class IdleDetectorTests: XCTestCase {

    var detector: IdleDetector!

    override func setUp() {
        super.setUp()
        detector = IdleDetector.shared
        detector.stop()
        detector.systemIdleTimeProvider = nil

        // Reset preferences to avoid test pollution
        PreferencesManager.shared.resetToDefaults()
    }

    override func tearDown() {
        detector.stop()
        detector.systemIdleTimeProvider = nil
        detector.onIdlePause = nil
        detector.onIdleResume = nil
        detector.onIdleReset = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(detector.isIdle)
        XCTAssertEqual(detector.idleSeconds, 0)
    }

    func testStopResetsState() {
        // Set some state artificially
        detector.systemIdleTimeProvider = { 100 }
        detector.checkIdleTime() // Will calculate idleSeconds = 100

        detector.stop()

        XCTAssertFalse(detector.isIdle)
        XCTAssertEqual(detector.idleSeconds, 0)
    }

    func testUserBecomesIdle() {
        // Setup preferences for this test
        PreferencesManager.shared.idlePauseMinutes = 1 // 60 seconds
        PreferencesManager.shared.idleResetMinutes = 5 // 300 seconds

        var pauseCalled = false
        detector.onIdlePause = { pauseCalled = true }

        // Mock idle time just above pause threshold
        detector.systemIdleTimeProvider = { 65 }
        detector.checkIdleTime()

        XCTAssertTrue(pauseCalled, "onIdlePause should be called when idle threshold is exceeded")
        XCTAssertTrue(detector.isIdle, "isIdle should be true")
        XCTAssertEqual(detector.idleSeconds, 65)
    }

    func testUserReturnsFromIdle() {
        // First trigger idle state
        PreferencesManager.shared.idlePauseMinutes = 1
        PreferencesManager.shared.idleResetMinutes = 5

        detector.systemIdleTimeProvider = { 65 }
        detector.checkIdleTime()
        XCTAssertTrue(detector.isIdle)

        // Setup for resume test
        var resumeCalled = false
        detector.onIdleResume = { resumeCalled = true }

        // Mock returning from idle (activity detected)
        detector.systemIdleTimeProvider = { 5 }
        detector.checkIdleTime()

        XCTAssertTrue(resumeCalled, "onIdleResume should be called when activity is detected")
        XCTAssertFalse(detector.isIdle, "isIdle should be false")
    }

    func testIdleReset() {
        PreferencesManager.shared.idlePauseMinutes = 1 // 60 seconds
        PreferencesManager.shared.idleResetMinutes = 5 // 300 seconds

        var resetCalled = false
        detector.onIdleReset = { resetCalled = true }

        // Mock long idle time
        detector.systemIdleTimeProvider = { 305 }
        detector.checkIdleTime()

        XCTAssertTrue(resetCalled, "onIdleReset should be called for long idle times")
        XCTAssertTrue(detector.isIdle)
    }

    func testThresholdPrecedence() {
        PreferencesManager.shared.idlePauseMinutes = 1
        PreferencesManager.shared.idleResetMinutes = 5

        var resetCalled = false
        var pauseCalled = false

        detector.onIdleReset = { resetCalled = true }
        detector.onIdlePause = { pauseCalled = true }

        // Mock idle time that exceeds BOTH thresholds
        detector.systemIdleTimeProvider = { 305 }
        detector.checkIdleTime()

        XCTAssertTrue(resetCalled, "Reset should take precedence")
        XCTAssertFalse(pauseCalled, "Pause should NOT be called if reset threshold is also met")
    }

    func testDisabledThresholds() {
        // Disable both thresholds
        PreferencesManager.shared.idlePauseMinutes = 0
        PreferencesManager.shared.idleResetMinutes = 0

        var resetCalled = false
        var pauseCalled = false

        detector.onIdleReset = { resetCalled = true }
        detector.onIdlePause = { pauseCalled = true }

        // Mock huge idle time
        detector.systemIdleTimeProvider = { 1000 }
        detector.checkIdleTime()

        XCTAssertFalse(resetCalled, "Reset should not be called when threshold is 0")
        XCTAssertFalse(pauseCalled, "Pause should not be called when threshold is 0")
    }
}
