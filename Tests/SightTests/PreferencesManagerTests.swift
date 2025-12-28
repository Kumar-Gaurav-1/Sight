import XCTest
@testable import Sight

final class PreferencesManagerTests: XCTestCase {
    
    var preferences: PreferencesManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.sight.tests")
        testDefaults.removePersistentDomain(forName: "com.sight.tests")
        preferences = PreferencesManager(defaults: testDefaults)
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.sight.tests")
        testDefaults = nil
        preferences = nil
        super.tearDown()
    }
    
    // MARK: - Default Values Tests
    
    func testDefaultWorkInterval() {
        XCTAssertEqual(preferences.workIntervalSeconds, 20 * 60)
    }
    
    func testDefaultPreBreakSeconds() {
        XCTAssertEqual(preferences.preBreakSeconds, 10)
    }
    
    func testDefaultBreakDuration() {
        XCTAssertEqual(preferences.breakDurationSeconds, 20)
    }
    
    func testDefaultLaunchAtLogin() {
        XCTAssertFalse(preferences.launchAtLogin)
    }
    
    func testDefaultSoundEnabled() {
        XCTAssertTrue(preferences.soundEnabled)
    }
    
    // MARK: - Persistence Tests
    
    func testWorkIntervalPersists() {
        preferences.workIntervalSeconds = 30 * 60
        
        let newPreferences = PreferencesManager(defaults: testDefaults)
        XCTAssertEqual(newPreferences.workIntervalSeconds, 30 * 60)
    }
    
    func testPreBreakSecondsPersists() {
        preferences.preBreakSeconds = 15
        
        let newPreferences = PreferencesManager(defaults: testDefaults)
        XCTAssertEqual(newPreferences.preBreakSeconds, 15)
    }
    
    func testBreakDurationPersists() {
        preferences.breakDurationSeconds = 30
        
        let newPreferences = PreferencesManager(defaults: testDefaults)
        XCTAssertEqual(newPreferences.breakDurationSeconds, 30)
    }
    
    // MARK: - Timer Configuration Bridge Tests
    
    func testTimerConfigurationBridge() {
        preferences.workIntervalSeconds = 600
        preferences.preBreakSeconds = 5
        preferences.breakDurationSeconds = 15
        
        let config = preferences.timerConfiguration
        XCTAssertEqual(config.workIntervalSeconds, 600)
        XCTAssertEqual(config.preBreakSeconds, 5)
        XCTAssertEqual(config.breakDurationSeconds, 15)
    }
    
    // MARK: - JSON Schema Tests
    
    func testSchemaJSONReturnsValidJSON() {
        let json = preferences.schemaJSON()
        
        let data = json.data(using: .utf8)
        XCTAssertNotNil(data)
        
        let parsed = try? JSONSerialization.jsonObject(with: data!, options: [])
        XCTAssertNotNil(parsed)
    }
    
    func testSchemaJSONContainsVersion() {
        let json = preferences.schemaJSON()
        XCTAssertTrue(json.contains("\"version\""))
    }
    
    func testSchemaJSONContainsPreferences() {
        let json = preferences.schemaJSON()
        XCTAssertTrue(json.contains("\"preferences\""))
        XCTAssertTrue(json.contains("\"workIntervalSeconds\""))
        XCTAssertTrue(json.contains("\"preBreakSeconds\""))
        XCTAssertTrue(json.contains("\"breakDurationSeconds\""))
    }
    
    // MARK: - Reset Tests
    
    func testResetToDefaults() {
        preferences.workIntervalSeconds = 100
        preferences.preBreakSeconds = 100
        preferences.breakDurationSeconds = 100
        preferences.launchAtLogin = true
        preferences.soundEnabled = false
        
        preferences.resetToDefaults()
        
        XCTAssertEqual(preferences.workIntervalSeconds, 20 * 60)
        XCTAssertEqual(preferences.preBreakSeconds, 10)
        XCTAssertEqual(preferences.breakDurationSeconds, 20)
        XCTAssertFalse(preferences.launchAtLogin)
        XCTAssertTrue(preferences.soundEnabled)
    }
}
