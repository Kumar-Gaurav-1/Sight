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

    func testExportToJSONSuccess() {
        let manager = AdherenceManager.shared
        manager.forceRefresh()

        let data = manager.exportToJSON()

        XCTAssertNotNil(data, "Exported JSON data should not be nil")

        if let data = data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                _ = try decoder.decode([AdherenceManager.DayStats].self, from: data)
            } catch {
                XCTFail("Failed to decode exported JSON: \(error)")
            }
        }
    }

    func testExportToJSONFailure() {
        let manager = AdherenceManager.shared

        // Inject extreme date into UserDefaults to simulate loading an extreme date
        // JSONDecoder defaults to .deferredToDate, which will decode the extreme date successfully,
        // but JSONEncoder with .iso8601 will fail to encode it, returning nil and logging an error.
        let extremeDate = Date(timeIntervalSince1970: 100000000000000)
        let invalidStats = [AdherenceManager.DayStats(date: extremeDate)]

        do {
            let data = try JSONEncoder().encode(invalidStats)
            UserDefaults.standard.set(data, forKey: "AdherenceStats")
        } catch {
            XCTFail("Failed to encode test data: \(error)")
        }

        // Force reload from UserDefaults
        manager.forceRefresh()

        let exportedData = manager.exportToJSON()

        XCTAssertNil(exportedData, "Exported JSON data should be nil for extreme dates")
    }
}
