import AppKit
import Combine
import os.log

// MARK: - Accessibility Manager

/// Centralized accessibility management for Sight
/// Monitors system accessibility preferences and provides consistent API
public final class AccessibilityManager: ObservableObject {
    
    // MARK: - Published State
    
    /// True when user has Reduce Motion enabled
    @Published public private(set) var reduceMotionEnabled: Bool = false
    
    /// True when VoiceOver is running
    @Published public private(set) var voiceOverRunning: Bool = false
    
    /// True when Reduce Transparency is enabled
    @Published public private(set) var reduceTransparencyEnabled: Bool = false
    
    /// True when Increase Contrast is enabled
    @Published public private(set) var increaseContrastEnabled: Bool = false
    
    /// Combined accessibility mode for quick checks
    @Published public private(set) var accessibilityMode: AccessibilityMode = .standard
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.accessibility", category: "Accessibility")
    private var cancellables = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []
    
    // MARK: - Singleton
    
    public static let shared = AccessibilityManager()
    
    // MARK: - Initialization
    
    public init() {
        refreshAllSettings()
        setupObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Public API
    
    /// Check if animations should be disabled/reduced
    public var shouldReduceAnimations: Bool {
        reduceMotionEnabled || voiceOverRunning
    }
    
    /// Get appropriate animation duration
    public func animationDuration(standard: TimeInterval) -> TimeInterval {
        shouldReduceAnimations ? 0 : standard
    }
    
    /// Get appropriate spring stiffness (1.0 = instant)
    public func springStiffness(standard: CGFloat) -> CGFloat {
        shouldReduceAnimations ? 1.0 : standard
    }
    
    /// Get appropriate spring damping (1.0 = critically damped = no bounce)
    public func springDamping(standard: CGFloat) -> CGFloat {
        shouldReduceAnimations ? 1.0 : standard
    }
    
    /// Force refresh all accessibility settings
    public func refresh() {
        refreshAllSettings()
    }
    
    // MARK: - Settings Detection
    
    private func refreshAllSettings() {
        // Reduce Motion - Primary API
        reduceMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        
        // VoiceOver - Check if running
        voiceOverRunning = NSWorkspace.shared.isVoiceOverEnabled
        
        // Reduce Transparency
        reduceTransparencyEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        
        // Increase Contrast
        increaseContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        
        // Update combined mode
        updateAccessibilityMode()
        
        logger.debug("Accessibility: motion=\(self.reduceMotionEnabled), voiceOver=\(self.voiceOverRunning)")
    }
    
    private func updateAccessibilityMode() {
        if voiceOverRunning {
            accessibilityMode = .voiceOver
        } else if reduceMotionEnabled {
            accessibilityMode = .reducedMotion
        } else if reduceTransparencyEnabled || increaseContrastEnabled {
            accessibilityMode = .highContrast
        } else {
            accessibilityMode = .standard
        }
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Reduce Motion changes
        let reduceMotionObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAllSettings()
        }
        observers.append(reduceMotionObserver)
        
        // VoiceOver changes
        let voiceOverObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAllSettings()
        }
        observers.append(voiceOverObserver)
        
        // Distributed notification for accessibility changes
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api.activeSessionChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAllSettings()
        }
    }
    
    private func removeObservers() {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
}

// MARK: - Accessibility Mode

/// Combined accessibility mode for streamlined handling
public enum AccessibilityMode: String, Codable {
    case standard       // No accessibility features active
    case reducedMotion  // Reduce Motion enabled
    case voiceOver      // VoiceOver running
    case highContrast   // High contrast/reduced transparency
    
    public var disableAnimations: Bool {
        switch self {
        case .standard: return false
        case .reducedMotion, .voiceOver, .highContrast: return true
        }
    }
    
    public var useSimplifiedUI: Bool {
        switch self {
        case .standard: return false
        case .reducedMotion, .voiceOver, .highContrast: return true
        }
    }
}

// MARK: - VoiceOver Labels

/// VoiceOver-friendly labels for all overlay elements
public struct AccessibilityLabels {
    
    // MARK: - Break Overlay
    
    public struct BreakOverlay {
        public static let container = "Break overlay is active"
        public static let countdown = { (seconds: Int) -> String in
            let minutes = seconds / 60
            let secs = seconds % 60
            if minutes > 0 {
                return "Break time remaining: \(minutes) minutes and \(secs) seconds"
            } else {
                return "Break time remaining: \(secs) seconds"
            }
        }
        public static let skipButton = "Skip break"
        public static let skipHint = "Double tap to skip this break"
        public static let breathingCircle = "Breathing animation. Follow the circle to relax."
    }
    
    // MARK: - Floating Counter
    
    public struct FloatingCounter {
        public static let container = "Break timer indicator"
        public static let timeRemaining = { (seconds: Int) -> String in
            let minutes = seconds / 60
            if minutes > 0 {
                return "\(minutes) minutes until next break"
            } else {
                return "\(seconds) seconds until next break"
            }
        }
        public static let status = { (state: String) -> String in
            "Timer status: \(state)"
        }
    }
    
    // MARK: - Nudges
    
    public struct Nudge {
        public static let blinkReminder = "Blink reminder. Remember to blink."
        public static let postureCheck = "Posture check. Sit up straight."
        public static let exercisePrompt = { (name: String) -> String in
            "Exercise suggestion: \(name)"
        }
        public static let snoozeButton = "Snooze nudge"
        public static let dismissButton = "Dismiss nudge"
    }
    
    // MARK: - Menu Bar
    
    public struct MenuBar {
        public static let statusItem = "Sight break timer"
        public static let statusWithTime = { (state: String, time: String) -> String in
            "Sight: \(state), \(time)"
        }
    }
}

// MARK: - Accessible View Protocol

/// Protocol for views that support accessibility
public protocol AccessibleView {
    func configureAccessibility()
    func updateAccessibilityLabel()
}

// MARK: - Animation Helpers

/// Animation utilities that respect accessibility settings
public struct AccessibleAnimation {
    
    private static var accessibility: AccessibilityManager { .shared }
    
    /// Standard animation duration respecting Reduce Motion
    public static var standardDuration: TimeInterval {
        accessibility.shouldReduceAnimations ? 0 : 0.3
    }
    
    /// Spring animation duration respecting Reduce Motion
    public static var springDuration: TimeInterval {
        accessibility.shouldReduceAnimations ? 0 : 0.5
    }
    
    /// Perform animation with accessibility check
    public static func animate(
        duration: TimeInterval = 0.3,
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        if accessibility.shouldReduceAnimations {
            animations()
            completion?()
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration
                context.allowsImplicitAnimation = true
                animations()
            }, completionHandler: completion)
        }
    }
    
    /// Perform spring animation with accessibility check
    public static func springAnimate(
        stiffness: CGFloat = 0.12,
        damping: CGFloat = 0.85,
        animations: @escaping () -> Void
    ) {
        if accessibility.shouldReduceAnimations {
            // Instant transition
            animations()
        } else {
            // Normal spring animation
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                animations()
            }
        }
    }
}

// MARK: - NSView Accessibility Extension

extension NSView {
    
    /// Configure view as an accessible element
    public func makeAccessible(
        label: String,
        role: NSAccessibility.Role = .group,
        hint: String? = nil
    ) {
        setAccessibilityElement(true)
        setAccessibilityRole(role)
        setAccessibilityLabel(label)
        if let hint = hint {
            setAccessibilityHelp(hint)
        }
    }
    
    /// Configure view as an accessible button
    public func makeAccessibleButton(
        label: String,
        hint: String? = nil,
        action: Selector? = nil
    ) {
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(label)
        if let hint = hint {
            setAccessibilityHelp(hint)
        }
    }
    
    /// Update dynamic accessibility label
    public func updateAccessibilityLabel(_ label: String) {
        setAccessibilityLabel(label)
        
        // Post notification for VoiceOver
        if AccessibilityManager.shared.voiceOverRunning {
            NSAccessibility.post(
                element: self,
                notification: .valueChanged
            )
        }
    }
}

// MARK: - NSWindow Accessibility Extension

extension NSWindow {
    
    /// Configure window for accessibility
    public func makeAccessibleOverlay(label: String) {
        setAccessibilityElement(true)
        setAccessibilityRole(.window)
        setAccessibilityLabel(label)
        setAccessibilityModal(true)
        
        // Announce when window appears
        if AccessibilityManager.shared.voiceOverRunning {
            NSAccessibility.post(
                element: self,
                notification: .created
            )
        }
    }
    
    /// Announce overlay dismissal
    public func announceOverlayDismissed() {
        if AccessibilityManager.shared.voiceOverRunning {
            // Post announcement
            let announcement = "Overlay dismissed"
            NSAccessibility.post(
                element: NSApp.mainWindow ?? self,
                notification: .announcementRequested,
                userInfo: [.announcement: announcement]
            )
        }
    }
}

// MARK: - Reduced Motion Spring Physics

/// Spring physics that instantly snaps when Reduce Motion is enabled
public struct AccessibleSpringPhysics {
    public var stiffness: CGFloat
    public var damping: CGFloat
    public var velocity: CGPoint = .zero
    
    private var accessibility: AccessibilityManager { .shared }
    
    public init(stiffness: CGFloat = 0.12, damping: CGFloat = 0.85) {
        self.stiffness = stiffness
        self.damping = damping
    }
    
    /// Update position with accessibility-aware physics
    public mutating func update(current: CGPoint, target: CGPoint, deltaTime: CGFloat) -> CGPoint {
        // When Reduce Motion enabled, snap instantly
        if AccessibilityManager.shared.shouldReduceAnimations {
            velocity = .zero
            return target
        }
        
        // Normal spring physics
        let displacement = CGPoint(
            x: current.x - target.x,
            y: current.y - target.y
        )
        
        let springForce = CGPoint(
            x: -stiffness * displacement.x,
            y: -stiffness * displacement.y
        )
        
        velocity = CGPoint(
            x: (velocity.x + springForce.x) * damping,
            y: (velocity.y + springForce.y) * damping
        )
        
        return CGPoint(
            x: current.x + velocity.x,
            y: current.y + velocity.y
        )
    }
    
    public func isSettled() -> Bool {
        abs(velocity.x) < 0.1 && abs(velocity.y) < 0.1
    }
    
    /// Reduced motion preset (instant snap)
    public static var reducedMotion: AccessibleSpringPhysics {
        AccessibleSpringPhysics(stiffness: 1.0, damping: 1.0)
    }
}
