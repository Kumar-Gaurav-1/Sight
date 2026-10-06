import XCTest
@testable import Sight

final class SharedFormattersTests: XCTestCase {

    func testSharedFormattersInitialization() {
        let formatters = SharedFormatters.shared

        // Test that properties are initialized and provide expected formats
        XCTAssertNotNil(formatters.iso8601)

        let date = Date(timeIntervalSince1970: 0) // 1970-01-01 00:00:00 UTC

        XCTAssertNotNil(formatters.dayName.string(from: date))
        XCTAssertNotNil(formatters.shortTime.string(from: date))
        XCTAssertNotNil(formatters.yyyyMMdd.string(from: date))
        XCTAssertNotNil(formatters.hourAmPm.string(from: date))
        XCTAssertNotNil(formatters.shortDayName.string(from: date))
    }
}
