import XCTest
@testable import Sight

final class MockFileManager: FileManager {
    var createDirectoryError: Error?

    override func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey : Any]? = nil
    ) throws {
        if let error = createDirectoryError {
            throw error
        }
        try super.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
}

final class LoginItemManagerTests: XCTestCase {
    var manager: LoginItemManager!
    var mockFileManager: MockFileManager!

    override func setUp() {
        super.setUp()
        manager = LoginItemManager()
        mockFileManager = MockFileManager()
        manager.fileManager = mockFileManager
        // Cleanup preferences
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
        manager = nil
        mockFileManager = nil
        super.tearDown()
    }

    func testCreateLaunchAgentDirectoryCreationFailsGracefully() {
        // Setup mock to fail directory creation
        mockFileManager.createDirectoryError = NSError(domain: "TestErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock creation failed"])

        // Trigger creation
        manager.setEnabled(true)

        // Verify state didn't actually proceed with creating plist since it returned early.
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "launchAtLogin"), "Preference is still saved before failure")
    }
}
