import XCTest
@testable import Sight

final class AdherenceManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        super.tearDown()
    }

    func testExportToJSON_EncodingError_ReturnsNil() throws {
        // Given
        // JSONEncoder with .iso8601 dateEncodingStrategy throws an error for extreme dates (e.g., year 10000).
        // JSONDecoder with default strategy successfully decodes these extreme dates.
        // We inject invalid data via UserDefaults to simulate and test encoding failure paths.
        let extremeDate = Date(timeIntervalSince1970: 253402300800) // Year 10000
        let stats = [AdherenceManager.DayStats(date: extremeDate)]

        let defaultEncoder = JSONEncoder()
        let data = try defaultEncoder.encode(stats)
        UserDefaults.standard.set(data, forKey: "AdherenceStats")

        // When
        // Instantiate a new AdherenceManager so it loads the extreme date from UserDefaults
        let manager = AdherenceManager()

        // Then
        // The exportToJSON method will fail to encode the extreme date using .iso8601 strategy
        let exportedData = manager.exportToJSON()

        XCTAssertNil(exportedData, "exportToJSON() should return nil when an encoding error occurs.")
    }
}
