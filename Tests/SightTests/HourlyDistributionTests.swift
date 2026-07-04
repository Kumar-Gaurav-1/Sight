import XCTest
@testable import Sight

final class HourlyDistributionTests: XCTestCase {

    func testInitialization() {
        let dist = HourlyDistribution()

        // Check that all 24 hours are initialized to 0 for breaks, nudges, pauses
        for hour in 0..<24 {
            XCTAssertEqual(dist.breaks[hour], 0)
            XCTAssertEqual(dist.nudges[hour], 0)
            XCTAssertEqual(dist.pauses[hour], 0)
        }
    }

    func testRecordBreak() {
        var dist = HourlyDistribution()

        dist.recordBreak(at: 9)
        dist.recordBreak(at: 9)
        dist.recordBreak(at: 14)

        XCTAssertEqual(dist.breaks[9], 2)
        XCTAssertEqual(dist.breaks[14], 1)
        XCTAssertEqual(dist.breaks[10], 0)
    }

    func testRecordNudge() {
        var dist = HourlyDistribution()

        dist.recordNudge(at: 10)
        dist.recordNudge(at: 15)

        XCTAssertEqual(dist.nudges[10], 1)
        XCTAssertEqual(dist.nudges[15], 1)
        XCTAssertEqual(dist.nudges[11], 0)
    }

    func testRecordPause() {
        var dist = HourlyDistribution()

        dist.recordPause(at: 12)

        XCTAssertEqual(dist.pauses[12], 1)
        XCTAssertEqual(dist.pauses[13], 0)
    }

    func testPeakBreakHour() {
        var dist = HourlyDistribution()

        dist.recordBreak(at: 10)
        dist.recordBreak(at: 10)
        dist.recordBreak(at: 14)

        XCTAssertEqual(dist.peakBreakHour, 10)
    }

    func testPeakActivityHours() {
        var dist = HourlyDistribution()

        dist.recordBreak(at: 9)
        dist.recordBreak(at: 10)
        dist.recordBreak(at: 10)
        dist.recordBreak(at: 14)
        dist.recordBreak(at: 14)
        dist.recordBreak(at: 14)
        dist.recordBreak(at: 16)

        let peakHours = dist.peakActivityHours
        XCTAssertEqual(peakHours.count, 3)
        XCTAssertEqual(peakHours[0], 14)
        XCTAssertEqual(peakHours[1], 10)

        // Third peak could be 9 or 16 because they both have count 1
        XCTAssertTrue(peakHours.contains(9) || peakHours.contains(16))
    }

    func testCodable() throws {
        var dist = HourlyDistribution()
        dist.recordBreak(at: 9)
        dist.recordNudge(at: 10)
        dist.recordPause(at: 11)

        let data = try JSONEncoder().encode(dist)
        let decoded = try JSONDecoder().decode(HourlyDistribution.self, from: data)

        XCTAssertEqual(decoded.breaks[9], 1)
        XCTAssertEqual(decoded.nudges[10], 1)
        XCTAssertEqual(decoded.pauses[11], 1)

        // Ensure unrecorded hours remained 0 after decode
        XCTAssertEqual(decoded.breaks[10], 0)
        XCTAssertEqual(decoded.nudges[9], 0)
    }
}
