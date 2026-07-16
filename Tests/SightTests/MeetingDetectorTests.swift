import XCTest
import EventKit
@testable import Sight

final class MeetingDetectorTests: XCTestCase {

    class MockEventStore: EKEventStore {
        var shouldThrowError: Bool = false

        override func requestAccess(to entityType: EKEntityType) async throws -> Bool {
            if shouldThrowError {
                throw NSError(domain: "MockErrorDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Mock authorization error"])
            }
            return true
        }

        @available(macOS 14.0, *)
        override func requestFullAccessToEvents() async throws -> Bool {
            if shouldThrowError {
                throw NSError(domain: "MockErrorDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Mock authorization error"])
            }
            return true
        }
    }

    override func setUp() {
        super.setUp()
        // Reset the event store before each test
        MeetingDetector.shared.eventStore = EKEventStore()
    }

    override func tearDown() {
        // Restore the event store after each test
        MeetingDetector.shared.eventStore = EKEventStore()
        super.tearDown()
    }

    func testRequestAccess_ThrowsError_ReturnsFalse() async {
        // Arrange
        let mockEventStore = MockEventStore()
        mockEventStore.shouldThrowError = true
        MeetingDetector.shared.eventStore = mockEventStore

        // Act
        let granted = await MeetingDetector.shared.requestAccess()

        // Assert
        XCTAssertFalse(granted, "requestAccess should return false when an error is thrown")
    }
}
