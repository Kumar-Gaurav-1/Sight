import XCTest
@testable import Sight

final class PauseEventTests: XCTestCase {

    func testInitialization() {
        let reason: PauseReason = .meeting
        let event = PauseEvent(reason: reason, relatedApp: "Zoom")

        XCTAssertEqual(event.reason, reason)
        XCTAssertEqual(event.relatedApp, "Zoom")
        XCTAssertNil(event.endTime)
        // `timestamp` is set to Date(), we just verify it exists
        XCTAssertNotNil(event.timestamp)
    }

    func testDurationWhenEndTimeIsNil() {
        let event = PauseEvent(reason: .idle)

        XCTAssertEqual(event.duration, 0)
        XCTAssertEqual(event.durationMinutes, 0)
    }

    func testDurationWithEndTime() {
        var event = PauseEvent(reason: .idle)
        let now = event.timestamp
        event.endTime = now.addingTimeInterval(120) // 2 minutes

        XCTAssertEqual(event.duration, 120)
        XCTAssertEqual(event.durationMinutes, 2)
    }

    func testDurationMinutesTruncation() {
        var event = PauseEvent(reason: .idle)
        let now = event.timestamp

        event.endTime = now.addingTimeInterval(59)
        XCTAssertEqual(event.durationMinutes, 0)

        event.endTime = now.addingTimeInterval(60)
        XCTAssertEqual(event.durationMinutes, 1)

        event.endTime = now.addingTimeInterval(119)
        XCTAssertEqual(event.durationMinutes, 1)

        event.endTime = now.addingTimeInterval(120)
        XCTAssertEqual(event.durationMinutes, 2)
    }

    func testCompleteMethodSetsEndTime() {
        var event = PauseEvent(reason: .manual)
        XCTAssertNil(event.endTime)

        event.complete()

        XCTAssertNotNil(event.endTime)
        XCTAssertTrue(event.endTime! >= event.timestamp)
    }
}
