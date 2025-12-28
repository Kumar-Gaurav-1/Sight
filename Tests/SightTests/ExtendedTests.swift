import XCTest
@testable import Sight

/// Mock Renderer API for testing
final class MockRendererAPI: RendererAPI {
    var showPreBreakCalled = false
    var showBreakCalled = false
    var showFloatingCounterCalled = false
    var updateCountdownCalled = false
    var hideCalled = false
    
    var lastPreBreakSeconds: Int = 0
    var lastBreakDuration: Int = 0
    var lastBreakStyle: BreakStyle = .calm
    var lastCountdownSeconds: Int = 0
    var lastFloatingCounterParams: FloatingCounterParams?
    
    var isAvailable: Bool = true
    
    func showPreBreak(preSeconds: Int) {
        showPreBreakCalled = true
        lastPreBreakSeconds = preSeconds
    }
    
    func showBreak(duration: Int, style: BreakStyle) {
        showBreakCalled = true
        lastBreakDuration = duration
        lastBreakStyle = style
    }
    
    func showFloatingCounter(params: FloatingCounterParams) {
        showFloatingCounterCalled = true
        lastFloatingCounterParams = params
    }
    
    func updateCountdown(remainingSeconds: Int) {
        updateCountdownCalled = true
        lastCountdownSeconds = remainingSeconds
    }
    
    func hide() {
        hideCalled = true
    }
    
    func showNudge(type: NudgeType) {
        // No-op for tests
    }
    
    func reset() {
        showPreBreakCalled = false
        showBreakCalled = false
        showFloatingCounterCalled = false
        updateCountdownCalled = false
        hideCalled = false
        lastPreBreakSeconds = 0
        lastBreakDuration = 0
        lastBreakStyle = .calm
        lastCountdownSeconds = 0
        lastFloatingCounterParams = nil
    }
}

// MARK: - Timer State Extended Tests

final class TimerStateExtendedTests: XCTestCase {
    
    // MARK: - State Transition Tests
    
    func testCompleteStateFlow() {
        let machine = TimerStateMachine(rendererEnabled: false)
        
        // Initial state
        XCTAssertEqual(machine.currentState, .idle)
        
        // Start
        machine.start()
        XCTAssertEqual(machine.currentState, .work)
        
        // Skip to pre-break
        machine.skipToNext()
        XCTAssertEqual(machine.currentState, .preBreak)
        
        // Skip to break
        machine.skipToNext()
        XCTAssertEqual(machine.currentState, .break)
        
        // Skip back to work
        machine.skipToNext()
        XCTAssertEqual(machine.currentState, .work)
        
        // Stop
        machine.stop()
        XCTAssertEqual(machine.currentState, .idle)
    }
    
    func testToggleFromEachState() {
        let machine = TimerStateMachine(rendererEnabled: false)
        
        // Toggle from idle -> work
        machine.toggle()
        XCTAssertEqual(machine.currentState, .work)
        
        // Toggle from work -> idle
        machine.toggle()
        XCTAssertEqual(machine.currentState, .idle)
        
        // Setup for pre-break test
        machine.start()
        machine.skipToNext() // work -> pre-break
        
        // Toggle from pre-break -> idle
        machine.toggle()
        XCTAssertEqual(machine.currentState, .idle)
    }
    
    func testStopFromAnyState() {
        let machine = TimerStateMachine(rendererEnabled: false)
        
        // Stop from work
        machine.start()
        machine.stop()
        XCTAssertEqual(machine.currentState, .idle)
        
        // Stop from pre-break
        machine.start()
        machine.skipToNext()
        machine.stop()
        XCTAssertEqual(machine.currentState, .idle)
        
        // Stop from break
        machine.start()
        machine.skipToNext()
        machine.skipToNext()
        machine.stop()
        XCTAssertEqual(machine.currentState, .idle)
    }
    
    // MARK: - Skip Logic Tests
    
    func testSkipFromIdleStarts() {
        let machine = TimerStateMachine(rendererEnabled: false)
        XCTAssertEqual(machine.currentState, .idle)
        
        // Skip from idle should start
        machine.skipToNext()
        XCTAssertEqual(machine.currentState, .work)
    }
    
    func testSkipResetsTimer() {
        let machine = TimerStateMachine(rendererEnabled: false)
        var config = TimerConfiguration.default
        config.workIntervalSeconds = 1200 // 20 min
        machine.configuration = config
        
        machine.start()
        XCTAssertEqual(machine.remainingSeconds, 1200)
        
        // Skip should reset timer for next state
        machine.skipToNext()
        // Now in pre-break, should have pre-break duration
        XCTAssertEqual(machine.remainingSeconds, config.preBreakSeconds)
    }
    
    func testMultipleSkipsInSuccession() {
        let machine = TimerStateMachine(rendererEnabled: false)
        machine.start()
        
        let states: [TimerState] = [.preBreak, .break, .work, .preBreak, .break]
        for expectedState in states {
            machine.skipToNext()
            XCTAssertEqual(machine.currentState, expectedState)
        }
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdateStopsTimer() {
        let machine = TimerStateMachine(rendererEnabled: false)
        machine.start()
        XCTAssertEqual(machine.currentState, .work)
        
        // Changing config should stop timer
        var newConfig = TimerConfiguration.default
        newConfig.workIntervalSeconds = 2400 // 40 min
        machine.configuration = newConfig
        
        // Timer should be stopped
        XCTAssertEqual(machine.currentState, .idle)
    }
}

// MARK: - Renderer API Mock Tests

final class RendererAPIMockTests: XCTestCase {
    
    var mockRenderer: MockRendererAPI!
    
    override func setUp() {
        super.setUp()
        mockRenderer = MockRendererAPI()
    }
    
    func testMockShowPreBreak() {
        mockRenderer.showPreBreak(preSeconds: 10)
        
        XCTAssertTrue(mockRenderer.showPreBreakCalled)
        XCTAssertEqual(mockRenderer.lastPreBreakSeconds, 10)
    }
    
    func testMockShowBreak() {
        mockRenderer.showBreak(duration: 20, style: .energize)
        
        XCTAssertTrue(mockRenderer.showBreakCalled)
        XCTAssertEqual(mockRenderer.lastBreakDuration, 20)
        XCTAssertEqual(mockRenderer.lastBreakStyle, .energize)
    }
    
    func testMockShowFloatingCounter() {
        let params = FloatingCounterParams()
        mockRenderer.showFloatingCounter(params: params)
        
        XCTAssertTrue(mockRenderer.showFloatingCounterCalled)
        XCTAssertNotNil(mockRenderer.lastFloatingCounterParams)
    }
    
    func testMockUpdateCountdown() {
        mockRenderer.updateCountdown(remainingSeconds: 300)
        
        XCTAssertTrue(mockRenderer.updateCountdownCalled)
        XCTAssertEqual(mockRenderer.lastCountdownSeconds, 300)
    }
    
    func testMockHide() {
        mockRenderer.hide()
        XCTAssertTrue(mockRenderer.hideCalled)
    }
    
    func testMockReset() {
        // Call all methods
        mockRenderer.showPreBreak(preSeconds: 10)
        mockRenderer.showBreak(duration: 20, style: .calm)
        mockRenderer.hide()
        
        // Reset
        mockRenderer.reset()
        
        // Verify all reset
        XCTAssertFalse(mockRenderer.showPreBreakCalled)
        XCTAssertFalse(mockRenderer.showBreakCalled)
        XCTAssertFalse(mockRenderer.hideCalled)
        XCTAssertEqual(mockRenderer.lastPreBreakSeconds, 0)
    }
    
    func testMockIsAvailable() {
        XCTAssertTrue(mockRenderer.isAvailable)
        
        mockRenderer.isAvailable = false
        XCTAssertFalse(mockRenderer.isAvailable)
    }
}

// MARK: - Smart Pause Extended Tests

final class SmartPauseExtendedTests: XCTestCase {
    
    func testPauseSignalCombinedWeights() {
        // Simulate multiple signals
        let signals: [PauseSignal] = [.meetingAppActive, .fullscreenApp]
        let weight = signals.reduce(0) { $0 + $1.weight }
        
        // 80 + 70 = 150
        XCTAssertEqual(weight, 150)
        XCTAssertGreaterThan(Double(weight), ThrottleThresholds.default.cpuThrottleDown)
    }
    
    func testSignalDisabling() {
        var config = SmartPauseConfig.default
        
        // Disable specific signal
        config.disabledSignals.insert(PauseSignal.screenRecording.rawValue)
        
        XCTAssertFalse(config.isSignalEnabled(.screenRecording))
        XCTAssertTrue(config.isSignalEnabled(.fullscreenApp))
    }
    
    func testAppWhitelisting() {
        var config = SmartPauseConfig.default
        
        config.whitelistedApps.insert("com.spotify.client")
        
        XCTAssertTrue(config.whitelistedApps.contains("com.spotify.client"))
        XCTAssertFalse(config.whitelistedApps.contains("us.zoom.xos"))
    }
    
    func testThresholdCustomization() {
        var config = SmartPauseConfig.default
        
        config.pauseThreshold = 80
        
        // Focus mode alone (60) should NOT meet threshold
        let focusWeight = PauseSignal.focusModeActive.weight
        XCTAssertLessThan(focusWeight, config.pauseThreshold)
        
        // Meeting app (80) should meet threshold
        let meetingWeight = PauseSignal.meetingAppActive.weight
        XCTAssertGreaterThanOrEqual(meetingWeight, config.pauseThreshold)
    }
    
    func testAllKnownMeetingAppsDetected() {
        let testBundleIds = [
            "us.zoom.xos",
            "com.microsoft.teams",
            "com.microsoft.teams2",
            "com.cisco.webexmeetingsapp",
            "com.slack.Slack",
            "com.discord.Discord",
            "com.apple.FaceTime"
        ]
        
        for bundleId in testBundleIds {
            XCTAssertTrue(
                KnownMeetingApps.isMeetingApp(bundleId),
                "Expected \(bundleId) to be detected as meeting app"
            )
        }
    }
    
    func testVideoAppsNotDetectedAsMeeting() {
        let videoApps = [
            "com.apple.QuickTimePlayerX",
            "org.videolan.vlc",
            "com.netflix.Netflix"
        ]
        
        for bundleId in videoApps {
            XCTAssertFalse(
                KnownMeetingApps.isMeetingApp(bundleId),
                "Video app \(bundleId) should NOT be detected as meeting app"
            )
            XCTAssertTrue(
                KnownMeetingApps.isVideoApp(bundleId),
                "Expected \(bundleId) to be detected as video app"
            )
        }
    }
}

// MARK: - Integration Tests

final class IntegrationTests: XCTestCase {
    
    func testTimerStateTransitions() {
        let timer = TimerStateMachine(rendererEnabled: false)
        
        // Simulate running state
        timer.start()
        XCTAssertEqual(timer.currentState, .work)
        
        // Verify timer is not idle
        XCTAssertNotEqual(timer.currentState, .idle)
        
        timer.stop()
        XCTAssertEqual(timer.currentState, .idle)
    }
    
    func testAccessibilityManagerExists() {
        let accessibility = AccessibilityManager.shared
        
        // Verify accessibility settings are accessible
        _ = accessibility.shouldReduceAnimations
        XCTAssertNotNil(accessibility)
    }
    
    func testProfilerAndQualityTierIntegration() {
        let profiler = RuntimeProfiler()
        
        // Force low tier
        profiler.forceQualityTier(.low)
        XCTAssertEqual(profiler.currentTier, .low)
        
        // Convert to overlay tier
        XCTAssertEqual(profiler.currentTier.overlayTier, .low)
    }
}
