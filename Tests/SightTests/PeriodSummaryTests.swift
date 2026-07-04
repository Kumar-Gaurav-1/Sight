import XCTest
@testable import Sight

final class PeriodSummaryTests: XCTestCase {

    func testBreakCompletionRate_Normal() {
        var summary = PeriodSummary()
        summary.breaksCompleted = 8
        summary.breaksSkipped = 2

        // 8 / (8 + 2) = 0.8
        XCTAssertEqual(summary.breakCompletionRate, 0.8, accuracy: 0.001)
    }

    func testBreakCompletionRate_ZeroBreaks() {
        var summary = PeriodSummary()
        summary.breaksCompleted = 0
        summary.breaksSkipped = 0

        // When total breaks is 0, the completion rate should be 1.0 (100%)
        XCTAssertEqual(summary.breakCompletionRate, 1.0, accuracy: 0.001)
    }

    func testAvgBreaksPerDay_Normal() {
        var summary = PeriodSummary()
        summary.breaksCompleted = 15
        summary.daysTracked = 5

        // 15 / 5 = 3.0
        XCTAssertEqual(summary.avgBreaksPerDay, 3.0, accuracy: 0.001)
    }

    func testAvgBreaksPerDay_ZeroDays() {
        var summary = PeriodSummary()
        summary.breaksCompleted = 5
        summary.daysTracked = 0

        // When days tracked is 0, should avoid division by zero and return 0
        XCTAssertEqual(summary.avgBreaksPerDay, 0.0, accuracy: 0.001)
    }

    func testAvgScreenTimePerDay_Normal() {
        var summary = PeriodSummary()
        summary.totalScreenTimeMinutes = 1000
        summary.daysTracked = 4

        // 1000 / 4 = 250
        XCTAssertEqual(summary.avgScreenTimePerDay, 250)
    }

    func testAvgScreenTimePerDay_ZeroDays() {
        var summary = PeriodSummary()
        summary.totalScreenTimeMinutes = 500
        summary.daysTracked = 0

        // When days tracked is 0, should avoid division by zero and return 0
        XCTAssertEqual(summary.avgScreenTimePerDay, 0)
    }

    func testInitialValues() {
        let summary = PeriodSummary()

        XCTAssertEqual(summary.totalScreenTimeMinutes, 0)
        XCTAssertEqual(summary.totalBreakTimeMinutes, 0)
        XCTAssertEqual(summary.totalMeetingMinutes, 0)
        XCTAssertEqual(summary.totalIdleMinutes, 0)
        XCTAssertEqual(summary.breaksCompleted, 0)
        XCTAssertEqual(summary.breaksSkipped, 0)
        XCTAssertEqual(summary.avgDailyScore, 100.0)
        XCTAssertEqual(summary.trend, .stable)
        XCTAssertEqual(summary.comparisonToPrevious, 0.0)
        XCTAssertEqual(summary.daysTracked, 0)
    }
}
