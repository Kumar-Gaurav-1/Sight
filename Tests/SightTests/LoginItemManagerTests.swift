import XCTest
@testable import Sight

final class LoginItemManagerTests: XCTestCase {

    var manager: LoginItemManager!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        manager = LoginItemManager.shared

        // Setup temporary directory for testing
        let tempDirPath = NSTemporaryDirectory()
        let uuid = UUID().uuidString
        tempDir = URL(fileURLWithPath: tempDirPath).appendingPathComponent(uuid)

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Reset properties
        manager.testLaunchAgentPath = nil

        // Remove temporary directory
        if let tempDir = tempDir {
            try? FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: tempDir.path)
            try? FileManager.default.removeItem(at: tempDir)
        }

        super.tearDown()
    }

    func testCreateLaunchAgentWriteFailure() {
        // Create a read-only directory
        let readOnlyDir = tempDir.appendingPathComponent("ReadOnlyDir")
        try! FileManager.default.createDirectory(at: readOnlyDir, withIntermediateDirectories: true)
        try! FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyDir.path)

        // Set test path to a file inside the read-only directory
        let testPath = readOnlyDir.appendingPathComponent("com.test.plist")
        manager.testLaunchAgentPath = testPath

        // Action: Set enabled to true, which triggers createLaunchAgent
        manager.setEnabled(true)

        // Verify: The file should not exist because writing failed
        XCTAssertFalse(FileManager.default.fileExists(atPath: testPath.path))
    }
}
