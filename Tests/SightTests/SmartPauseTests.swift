import XCTest
@testable import Sight

final class SmartPauseTests: XCTestCase {
    
    // MARK: - Pause Signal Tests
    
    func testPauseSignalWeights() {
        // Verify priority order
        XCTAssertEqual(PauseSignal.screenRecording.weight, 100)
        XCTAssertEqual(PauseSignal.screenSharing.weight, 95)
        XCTAssertEqual(PauseSignal.fullscreenVideo.weight, 90)
        XCTAssertEqual(PauseSignal.presentationMode.weight, 85)
        XCTAssertEqual(PauseSignal.meetingAppActive.weight, 80)
        XCTAssertEqual(PauseSignal.fullscreenApp.weight, 70)
        XCTAssertEqual(PauseSignal.focusModeActive.weight, 60)
        XCTAssertEqual(PauseSignal.calendarMeeting.weight, 50)
    }
    
    func testPauseSignalPriorityOrder() {
        // Higher weight = more important
        XCTAssertGreaterThan(PauseSignal.screenRecording.weight, PauseSignal.screenSharing.weight)
        XCTAssertGreaterThan(PauseSignal.screenSharing.weight, PauseSignal.fullscreenVideo.weight)
        XCTAssertGreaterThan(PauseSignal.fullscreenVideo.weight, PauseSignal.meetingAppActive.weight)
        XCTAssertGreaterThan(PauseSignal.meetingAppActive.weight, PauseSignal.fullscreenApp.weight)
        XCTAssertGreaterThan(PauseSignal.fullscreenApp.weight, PauseSignal.focusModeActive.weight)
        XCTAssertGreaterThan(PauseSignal.focusModeActive.weight, PauseSignal.calendarMeeting.weight)
    }
    
    func testPauseSignalDescriptions() {
        for signal in PauseSignal.allCases {
            XCTAssertFalse(signal.description.isEmpty)
        }
    }
    
    // MARK: - Known Meeting Apps Tests
    
    func testZoomDetection() {
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("us.zoom.xos"))
    }
    
    func testTeamsDetection() {
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("com.microsoft.teams"))
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("com.microsoft.teams2"))
    }
    
    func testWebexDetection() {
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("com.cisco.webexmeetingsapp"))
    }
    
    func testSlackDetection() {
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("com.slack.Slack"))
    }
    
    func testDiscordDetection() {
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("com.discord.Discord"))
    }
    
    func testOBSDetection() {
        XCTAssertTrue(KnownMeetingApps.isMeetingApp("com.obsproject.obs-studio"))
    }
    
    func testUnknownAppNotDetected() {
        XCTAssertFalse(KnownMeetingApps.isMeetingApp("com.example.unknown"))
        XCTAssertFalse(KnownMeetingApps.isMeetingApp("com.apple.Safari"))
    }
    
    func testVideoAppDetection() {
        XCTAssertTrue(KnownMeetingApps.isVideoApp("com.apple.QuickTimePlayerX"))
        XCTAssertTrue(KnownMeetingApps.isVideoApp("org.videolan.vlc"))
        XCTAssertFalse(KnownMeetingApps.isVideoApp("com.apple.Safari"))
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfigThreshold() {
        let config = SmartPauseConfig.default
        XCTAssertEqual(config.pauseThreshold, 80)
    }
    
    func testDefaultConfigPollingInterval() {
        let config = SmartPauseConfig.default
        XCTAssertEqual(config.pollingInterval, 2.0)
    }
    
    func testDefaultConfigDetectionEnabled() {
        let config = SmartPauseConfig.default
        XCTAssertFalse(config.detectFullscreen) // Disabled by default to avoid false pauses
        XCTAssertTrue(config.detectScreenRecording)
        XCTAssertTrue(config.detectFocusMode)
        XCTAssertTrue(config.detectMeetingApps)
    }
    
    func testSignalEnableDisable() {
        var config = SmartPauseConfig.default
        
        // All signals enabled by default
        XCTAssertTrue(config.isSignalEnabled(.screenRecording))
        XCTAssertTrue(config.isSignalEnabled(.fullscreenApp))
        
        // Disable a signal
        config.disabledSignals.insert(PauseSignal.screenRecording.rawValue)
        XCTAssertFalse(config.isSignalEnabled(.screenRecording))
        XCTAssertTrue(config.isSignalEnabled(.fullscreenApp))
    }
    
    func testWhitelistedApps() {
        var config = SmartPauseConfig.default
        XCTAssertTrue(config.whitelistedApps.isEmpty)
        
        config.whitelistedApps.insert("com.example.myapp")
        XCTAssertTrue(config.whitelistedApps.contains("com.example.myapp"))
    }
    
    // MARK: - Weight Calculation Tests
    
    func testSingleSignalWeight() {
        let signals: [PauseSignal] = [.focusModeActive]
        let weight = signals.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(weight, 60)
    }
    
    func testMultipleSignalsWeight() {
        let signals: [PauseSignal] = [.screenRecording, .meetingAppActive]
        let weight = signals.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(weight, 180) // 100 + 80
    }
    
    func testFocusModeAloneDoesNotMeetThreshold() {
        let config = SmartPauseConfig.default
        let signals: [PauseSignal] = [.focusModeActive]
        let weight = signals.reduce(0) { $0 + $1.weight }
        
        // Focus mode weight (60) should NOT meet default threshold (80)
        XCTAssertLessThan(weight, config.pauseThreshold)
    }
    
    func testCalendarMeetingAloneDoesNotMeetThreshold() {
        let config = SmartPauseConfig.default
        let signals: [PauseSignal] = [.calendarMeeting]
        let weight = signals.reduce(0) { $0 + $1.weight }
        
        // Calendar meeting weight (50) should NOT meet default threshold (80)
        XCTAssertLessThan(weight, config.pauseThreshold)
    }
    
    // MARK: - Codable Tests
    
    func testConfigCodable() throws {
        var config = SmartPauseConfig.default
        config.pauseThreshold = 75
        config.disabledSignals.insert("screenRecording")
        config.whitelistedApps.insert("com.example.app")
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SmartPauseConfig.self, from: data)
        
        XCTAssertEqual(decoded.pauseThreshold, 75)
        XCTAssertTrue(decoded.disabledSignals.contains("screenRecording"))
        XCTAssertTrue(decoded.whitelistedApps.contains("com.example.app"))
    }
    
    func testPauseSignalCodable() throws {
        let signal = PauseSignal.screenRecording
        let data = try JSONEncoder().encode(signal)
        let decoded = try JSONDecoder().decode(PauseSignal.self, from: data)
        
        XCTAssertEqual(decoded, signal)
    }
    
    // MARK: - Manager Tests
    
    func testSmartPauseManagerSharedInstance() {
        let manager = SmartPauseManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testSmartPauseManagerInitialState() {
        let manager = SmartPauseManager(config: .default)
        XCTAssertFalse(manager.shouldPause)
        XCTAssertTrue(manager.activeSignals.isEmpty)
        XCTAssertEqual(manager.totalWeight, 0)
    }
}
