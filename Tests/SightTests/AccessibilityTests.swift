import XCTest
@testable import Sight

final class AccessibilityTests: XCTestCase {
    
    // MARK: - Accessibility Mode Tests
    
    func testAccessibilityModeStandard() {
        let mode = AccessibilityMode.standard
        XCTAssertFalse(mode.disableAnimations)
        XCTAssertFalse(mode.useSimplifiedUI)
    }
    
    func testAccessibilityModeReducedMotion() {
        let mode = AccessibilityMode.reducedMotion
        XCTAssertTrue(mode.disableAnimations)
        XCTAssertTrue(mode.useSimplifiedUI)
    }
    
    func testAccessibilityModeVoiceOver() {
        let mode = AccessibilityMode.voiceOver
        XCTAssertTrue(mode.disableAnimations)
        XCTAssertTrue(mode.useSimplifiedUI)
    }
    
    func testAccessibilityModeHighContrast() {
        let mode = AccessibilityMode.highContrast
        XCTAssertTrue(mode.disableAnimations)
        XCTAssertTrue(mode.useSimplifiedUI)
    }
    
    func testAccessibilityModeCodable() throws {
        for mode in [AccessibilityMode.standard, .reducedMotion, .voiceOver, .highContrast] {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(AccessibilityMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }
    
    // MARK: - Accessibility Labels Tests
    
    func testBreakOverlayLabels() {
        XCTAssertFalse(AccessibilityLabels.BreakOverlay.container.isEmpty)
        XCTAssertFalse(AccessibilityLabels.BreakOverlay.skipButton.isEmpty)
        XCTAssertFalse(AccessibilityLabels.BreakOverlay.skipHint.isEmpty)
    }
    
    func testBreakOverlayCountdownLabel() {
        // Test minutes and seconds
        let label90 = AccessibilityLabels.BreakOverlay.countdown(90)
        XCTAssertTrue(label90.contains("1 minutes"))
        XCTAssertTrue(label90.contains("30 seconds"))
        
        // Test seconds only
        let label30 = AccessibilityLabels.BreakOverlay.countdown(30)
        XCTAssertTrue(label30.contains("30 seconds"))
        XCTAssertFalse(label30.contains("minutes"))
    }
    
    func testFloatingCounterLabels() {
        XCTAssertFalse(AccessibilityLabels.FloatingCounter.container.isEmpty)
        
        // Test time remaining
        let label5min = AccessibilityLabels.FloatingCounter.timeRemaining(300)
        XCTAssertTrue(label5min.contains("5 minutes"))
        
        let label30sec = AccessibilityLabels.FloatingCounter.timeRemaining(30)
        XCTAssertTrue(label30sec.contains("30 seconds"))
    }
    
    func testNudgeLabels() {
        XCTAssertFalse(AccessibilityLabels.Nudge.blinkReminder.isEmpty)
        XCTAssertFalse(AccessibilityLabels.Nudge.postureCheck.isEmpty)
        XCTAssertFalse(AccessibilityLabels.Nudge.snoozeButton.isEmpty)
        XCTAssertFalse(AccessibilityLabels.Nudge.dismissButton.isEmpty)
        
        let exerciseLabel = AccessibilityLabels.Nudge.exercisePrompt("Neck Rolls")
        XCTAssertTrue(exerciseLabel.contains("Neck Rolls"))
    }
    
    func testMenuBarLabels() {
        XCTAssertFalse(AccessibilityLabels.MenuBar.statusItem.isEmpty)
        
        let statusLabel = AccessibilityLabels.MenuBar.statusWithTime("Working", "5:00")
        XCTAssertTrue(statusLabel.contains("Working"))
        XCTAssertTrue(statusLabel.contains("5:00"))
    }
    
    // MARK: - Accessible Animation Tests
    
    func testStandardDurationProperty() {
        // This tests the computed property exists
        let duration = AccessibleAnimation.standardDuration
        XCTAssertGreaterThanOrEqual(duration, 0)
    }
    
    func testSpringDurationProperty() {
        let duration = AccessibleAnimation.springDuration
        XCTAssertGreaterThanOrEqual(duration, 0)
    }
    
    // MARK: - Accessible Spring Physics Tests
    
    func testAccessibleSpringPhysicsInitialization() {
        let spring = AccessibleSpringPhysics(stiffness: 0.12, damping: 0.85)
        XCTAssertEqual(spring.stiffness, 0.12)
        XCTAssertEqual(spring.damping, 0.85)
        XCTAssertEqual(spring.velocity, .zero)
    }
    
    func testAccessibleSpringPhysicsReducedMotionPreset() {
        let spring = AccessibleSpringPhysics.reducedMotion
        XCTAssertEqual(spring.stiffness, 1.0)
        XCTAssertEqual(spring.damping, 1.0)
    }
    
    func testAccessibleSpringPhysicsIsSettled() {
        var spring = AccessibleSpringPhysics()
        XCTAssertTrue(spring.isSettled()) // Initial velocity is zero
        
        // After update with movement
        _ = spring.update(current: .zero, target: CGPoint(x: 100, y: 100), deltaTime: 1.0/60.0)
        // May or may not be settled depending on accessibility state
    }
    
    // MARK: - Manager Tests
    
    func testAccessibilityManagerSharedInstance() {
        let manager = AccessibilityManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testAccessibilityManagerProperties() {
        let manager = AccessibilityManager.shared
        
        // These are system-dependent, just verify they return valid values
        _ = manager.reduceMotionEnabled
        _ = manager.voiceOverRunning
        _ = manager.reduceTransparencyEnabled
        _ = manager.increaseContrastEnabled
        _ = manager.accessibilityMode
        _ = manager.shouldReduceAnimations
    }
    
    func testAnimationDurationHelper() {
        let manager = AccessibilityManager.shared
        let standard: TimeInterval = 0.5
        
        let result = manager.animationDuration(standard: standard)
        
        // Should be either 0 (if reduce motion) or standard
        XCTAssertTrue(result == 0 || result == standard)
    }
    
    func testSpringStiffnessHelper() {
        let manager = AccessibilityManager.shared
        let standardStiffness: CGFloat = 0.12
        
        let result = manager.springStiffness(standard: standardStiffness)
        
        // Should be either 1.0 (instant) or standard
        XCTAssertTrue(result == 1.0 || result == standardStiffness)
    }
    
    func testSpringDampingHelper() {
        let manager = AccessibilityManager.shared
        let standardDamping: CGFloat = 0.85
        
        let result = manager.springDamping(standard: standardDamping)
        
        // Should be either 1.0 (critically damped) or standard
        XCTAssertTrue(result == 1.0 || result == standardDamping)
    }
    
    func testRefreshSettings() {
        let manager = AccessibilityManager.shared
        // Should not throw
        manager.refresh()
    }
}
