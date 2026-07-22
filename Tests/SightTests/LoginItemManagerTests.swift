import XCTest
@testable import Sight

class MockFileManager: FileManager {
    var shouldFailCreateDirectory = false

    override var homeDirectoryForCurrentUser: URL {
        let path = NSTemporaryDirectory() + "TestHome"
        return URL(fileURLWithPath: path)
    }

    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        if shouldFailCreateDirectory {
            throw NSError(domain: "TestMockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Directory Creation Failure"])
        }
        try super.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
}

final class LoginItemManagerTests: XCTestCase {

    var loginItemManager: LoginItemManager!
    var mockFileManager: MockFileManager!

    override func setUp() {
        super.setUp()
        loginItemManager = LoginItemManager.shared
        mockFileManager = MockFileManager()
        loginItemManager.fileManager = mockFileManager

        // Ensure clean test environment
        do {
            let homeDir = mockFileManager.homeDirectoryForCurrentUser
            if mockFileManager.fileExists(atPath: homeDir.path) {
                try mockFileManager.removeItem(at: homeDir)
            }
        } catch {
            print("Failed to clean up test home dir: \(error)")
        }
    }

    override func tearDown() {
        loginItemManager.fileManager = .default
        mockFileManager = nil
        loginItemManager = nil
        super.tearDown()
    }

    func testSetEnabled_WhenCreateDirectoryFails_DoesNotCreateLaunchAgent() {
        // Arrange
        mockFileManager.shouldFailCreateDirectory = true

        // Act
        loginItemManager.setEnabled(true)

        // Assert
        XCTAssertFalse(loginItemManager.isEnabled, "LaunchAgent should not be created if directory creation fails")
    }
}
