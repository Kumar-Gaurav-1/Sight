import XCTest
@testable import Sight

class MockFileManagerForLoginItem: FileManager {
    var shouldFailCreateDirectory = false
    var createdDirectoryURL: URL?
    var didCheckFileExists = false
    var fileExistsResult = false

    override var homeDirectoryForCurrentUser: URL {
        return URL(fileURLWithPath: "/tmp/mock_home")
    }

    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        createdDirectoryURL = url
        if shouldFailCreateDirectory {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock creation failure"])
        }
    }

    override func fileExists(atPath path: String) -> Bool {
        didCheckFileExists = true
        return fileExistsResult
    }
}

final class LoginItemManagerTests: XCTestCase {

    func testCreateDirectoryFailure() {
        let manager = LoginItemManager()
        let mockFileManager = MockFileManagerForLoginItem()
        mockFileManager.shouldFailCreateDirectory = true
        manager.fileManager = mockFileManager

        manager.setEnabled(true)

        XCTAssertNotNil(mockFileManager.createdDirectoryURL)
        let expectedURL = URL(fileURLWithPath: "/tmp/mock_home/Library/LaunchAgents")
        XCTAssertEqual(mockFileManager.createdDirectoryURL, expectedURL)
    }
}
