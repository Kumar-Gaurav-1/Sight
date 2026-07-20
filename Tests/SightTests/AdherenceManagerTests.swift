import XCTest
@testable import Sight

final class AdherenceManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        super.tearDown()
    }

    func testExportToJSON_ErrorPath() throws {
        // Create stats with an extreme date that ISO8601 encoder cannot format (throws error)
        let extremeDate = Date(timeIntervalSince1970: 10000000000000)
        let badDay = AdherenceManager.DayStats(date: extremeDate)

        // Encode with default strategy (.deferredToDate) and save to UserDefaults
        let encoder = JSONEncoder()
        let data = try encoder.encode([badDay])
        UserDefaults.standard.set(data, forKey: "AdherenceStats")

        // Initialize AdherenceManager, which will load the stats
        let manager = AdherenceManager()

        // exportToJSON uses .iso8601 strategy which should throw and return nil
        let json = manager.exportToJSON()

        // Assert it failed gracefully and returned nil
        XCTAssertNil(json, "Exporting JSON with extreme dates should fail and return nil")
    }
}
