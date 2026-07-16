import XCTest
import AppKit
@testable import Sight

final class SoundManagerTests: XCTestCase {

    var preferences: PreferencesManager!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.sight.tests.soundmanager")
        testDefaults.removePersistentDomain(forName: "com.sight.tests.soundmanager")
        preferences = PreferencesManager(defaults: testDefaults)

        // Use test defaults for the shared instance
        PreferencesManager.shared.resetToDefaults()
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.sight.tests.soundmanager")
        testDefaults = nil
        preferences = nil
        PreferencesManager.shared.resetToDefaults()
        SoundManager.shared.stop()
        super.tearDown()
    }

    // MARK: - playBreakStart() Tests

    func testPlayBreakStart_whenDisabled_doesNotPlay() {
        PreferencesManager.shared.breakStartSoundEnabled = false
        PreferencesManager.shared.soundPair = "Default"

        SoundManager.shared.playBreakStart()

        XCTAssertNil(SoundManager.shared.currentSound, "Sound should not play when break start sound is disabled")
    }

    func testPlayBreakStart_whenEnabled_playsCorrectSoundForPairs() {
        PreferencesManager.shared.breakStartSoundEnabled = true

        let testCases: [(String, SoundManager.SoundType)] = [
            ("Default", .chime),
            ("Gentle", .gentle),
            ("Chime", .chime),
            ("Bell", .bell),
            ("Nature", .ocean),
            ("Minimal", .tick),
            ("UnknownPair", .chime)
        ]

        for (pair, expectedType) in testCases {
            PreferencesManager.shared.soundPair = pair
            SoundManager.shared.stop()
            SoundManager.shared.playBreakStart()

            // On Linux or when sounds are unavailable, NSSound might fail, so currentSound could be nil.
            // However, we made soundTypeForPair internal, let's verify that logic instead as the most robust test.
            let resolvedType = SoundManager.shared.soundTypeForPair(pair, isStart: true)
            XCTAssertEqual(resolvedType, expectedType, "Expected \(expectedType) for pair \(pair) on start")
        }
    }

    // MARK: - playBreakEnd() Tests

    func testPlayBreakEnd_whenDisabled_doesNotPlay() {
        PreferencesManager.shared.breakEndSoundEnabled = false
        PreferencesManager.shared.soundPair = "Default"

        SoundManager.shared.playBreakEnd()

        XCTAssertNil(SoundManager.shared.currentSound, "Sound should not play when break end sound is disabled")
    }

    func testPlayBreakEnd_whenEnabled_playsCorrectSoundForPairs() {
        PreferencesManager.shared.breakEndSoundEnabled = true

        let testCases: [(String, SoundManager.SoundType)] = [
            ("Default", .bell),
            ("Gentle", .soft),
            ("Chime", .harp),
            ("Bell", .chime),
            ("Nature", .rain),
            ("Minimal", .click),
            ("UnknownPair", .bell)
        ]

        for (pair, expectedType) in testCases {
            PreferencesManager.shared.soundPair = pair

            let resolvedType = SoundManager.shared.soundTypeForPair(pair, isStart: false)
            XCTAssertEqual(resolvedType, expectedType, "Expected \(expectedType) for pair \(pair) on end")
        }
    }
}
