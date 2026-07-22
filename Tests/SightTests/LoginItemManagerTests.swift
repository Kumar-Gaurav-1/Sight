import XCTest
@testable import Sight

final class LoginItemManagerTests: XCTestCase {

    func testCreateLaunchAgentErrorPath() {
        let manager = LoginItemManager()

        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            XCTFail("Failed to create temp dir")
            return
        }

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Set the launchAgentPath to the temporary directory ITSELF.
        // The directory creation in setEnabled() will succeed because tempDir.deletingLastPathComponent() exists.
        // However, writing the plist file to this path will fail because it's a directory,
        // which will hit the target catch block for plist writing.
        manager.launchAgentPath = tempDir

        // This should not crash, but correctly catch and log the error
        manager.setEnabled(true)

        // Verification: The directory should still exist as a directory, meaning the write failed as expected
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempDir.path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDir.boolValue)
    }
}
