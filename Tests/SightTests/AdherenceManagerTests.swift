import XCTest
@testable import Sight

final class AdherenceManagerTests: XCTestCase {

    var manager: AdherenceManager!

    override func setUp() {
        super.setUp()
        // Reset defaults for adherence keys
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        manager = AdherenceManager.shared
        manager.resetAllStats()
    }

    override func tearDown() {
        manager.resetAllStats()
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        manager = nil
        super.tearDown()
    }

    func testExportToJSON_Success() {
        // Record some stats
        manager.recordBreak(completed: true, duration: 5)

        let jsonData = manager.exportToJSON()
        XCTAssertNotNil(jsonData, "Exported JSON data should not be nil on success")

        // Verify it can be decoded back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let stats = try decoder.decode([AdherenceManager.DayStats].self, from: jsonData!)
            XCTAssertFalse(stats.isEmpty, "Exported stats should contain data")
        } catch {
            XCTFail("Failed to decode exported JSON: \(error)")
        }
    }

    func testExportToJSON_EncodingErrorReturnsNil() {
        // Inject an extreme date that ISO8601DateFormatter cannot encode
        // A date way into the future (e.g., year 10000) causes ISO8601DateFormatter to fail.
        let extremeDate = Date(timeIntervalSince1970: 253402300800) // Year 10000
        let extremeStats = [AdherenceManager.DayStats(date: extremeDate)]

        // Save the extreme date to UserDefaults using standard encoding
        // which defaults to .deferredToDate (a number), so it saves fine.
        if let encoded = try? JSONEncoder().encode(extremeStats) {
            UserDefaults.standard.set(encoded, forKey: "AdherenceStats")
        } else {
            XCTFail("Failed to setup extreme stats")
            return
        }

        // Re-initialize manager to load the extreme stats from UserDefaults
        manager = AdherenceManager()

        // Now calling exportToJSON() should fail because it explicitly uses .iso8601 strategy,
        // which throws an error for dates with years > 9999.
        let jsonData = manager.exportToJSON()

        XCTAssertNil(jsonData, "exportToJSON should return nil when encoding fails")
    }
}
