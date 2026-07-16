import XCTest
@testable import Sight

final class AdherenceManagerTests: XCTestCase {
    var adherenceManager: AdherenceManager!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")

        adherenceManager = AdherenceManager()
    }

    override func tearDown() {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "AdherenceDailyGoal")
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        adherenceManager = nil
        super.tearDown()
    }

    func testSaveExport_createDirectoryFailsWhenFileExistsAtPath() throws {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get documents directory")
            return
        }

        let sightURL = documentsURL.appendingPathComponent("Sight")
        try? fileManager.createDirectory(at: sightURL, withIntermediateDirectories: true)

        let exportsPath = sightURL.appendingPathComponent("exports")

        // Remove if exists
        try? fileManager.removeItem(at: exportsPath)

        // Create a regular file at the path where the directory needs to be created
        try "test".write(to: exportsPath, atomically: true, encoding: .utf8)

        addTeardownBlock {
            try? fileManager.removeItem(at: exportsPath)
        }

        // Ensure the file exists
        XCTAssertTrue(fileManager.fileExists(atPath: exportsPath.path))

        let url = adherenceManager.saveExport(format: .json)
        XCTAssertNil(url, "Expected saveExport to fail and return nil because directory creation should fail")
    }

    func testSaveExport_fileWriteFailsWhenDirectoryIsReadOnly() throws {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get documents directory")
            return
        }

        let sightURL = documentsURL.appendingPathComponent("Sight")
        try? fileManager.createDirectory(at: sightURL, withIntermediateDirectories: true)

        let exportsPath = sightURL.appendingPathComponent("exports")

        // Create directory
        try? fileManager.createDirectory(at: exportsPath, withIntermediateDirectories: true)

        addTeardownBlock {
            try? fileManager.setAttributes([.posixPermissions: 0o777], ofItemAtPath: exportsPath.path)
            try? fileManager.removeItem(at: exportsPath)
        }

        // Make directory read-only
        try fileManager.setAttributes([.posixPermissions: 0o555], ofItemAtPath: exportsPath.path)

        let url = adherenceManager.saveExport(format: .json)
        XCTAssertNil(url, "Expected saveExport to fail and return nil because writing to the directory should fail")
    }
}
