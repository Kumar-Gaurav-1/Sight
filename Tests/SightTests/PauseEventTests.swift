import XCTest
@testable import Sight

final class PauseEventTests: XCTestCase {

    // MARK: - Duration Tests

    func testDurationWhenIncomplete() {
        let event = PauseEvent(reason: .meeting)
        XCTAssertNil(event.endTime)
        XCTAssertEqual(event.duration, 0)
        XCTAssertEqual(event.durationMinutes, 0)
    }

    func testDurationWhenComplete() {
        var event = PauseEvent(reason: .meeting)
        let startTime = event.timestamp
        // Simulate a 150-second pause
        event.endTime = startTime.addingTimeInterval(150)

        XCTAssertEqual(event.duration, 150)
        XCTAssertEqual(event.durationMinutes, 2)
    }

    func testDurationMinutesRoundingDown() {
        var event = PauseEvent(reason: .idle)
        let startTime = event.timestamp

        // 59 seconds -> 0 minutes
        event.endTime = startTime.addingTimeInterval(59)
        XCTAssertEqual(event.durationMinutes, 0)

        // 60 seconds -> 1 minute
        event.endTime = startTime.addingTimeInterval(60)
        XCTAssertEqual(event.durationMinutes, 1)

        // 119 seconds -> 1 minute
        event.endTime = startTime.addingTimeInterval(119)
        XCTAssertEqual(event.durationMinutes, 1)
    }

    // MARK: - Method Tests

    func testCompleteMethod() {
        var event = PauseEvent(reason: .manual)
        XCTAssertNil(event.endTime)

        event.complete()

        XCTAssertNotNil(event.endTime)

        // Verify that endTime is reasonably close to the current time
        if let endTime = event.endTime {
            let timeDifference = Date().timeIntervalSince(endTime)
            // It should be extremely close since we just called complete()
            XCTAssertLessThan(abs(timeDifference), 1.0, "endTime should be set to the current time")
        } else {
            XCTFail("endTime should not be nil after calling complete()")
        }
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        let reason = PauseReason.screenRecording
        let relatedApp = "QuickTime Player"
        let event = PauseEvent(reason: reason, relatedApp: relatedApp)

        XCTAssertEqual(event.reason, reason)
        XCTAssertEqual(event.relatedApp, relatedApp)
        XCTAssertNil(event.endTime)

        // Timestamp should be close to now
        let timeDifference = Date().timeIntervalSince(event.timestamp)
        XCTAssertLessThan(abs(timeDifference), 1.0)
    }
}
