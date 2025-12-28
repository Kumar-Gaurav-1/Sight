import AppKit
import Combine
import os.log

// MARK: - Spring Physics Engine

/// Lightweight spring physics for smooth animations
public struct SpringPhysics {

    /// Spring stiffness (k) - higher = faster response
    public var stiffness: CGFloat

    /// Damping ratio - higher = less oscillation (0-1 range typically)
    public var damping: CGFloat

    /// Current velocity
    public var velocity: CGPoint = .zero

    /// Default tuning parameters matching acceptance test
    public static let `default` = SpringPhysics(stiffness: 0.12, damping: 0.85)

    /// Low motion alternative (faster settling, less spring)
    public static let reducedMotion = SpringPhysics(stiffness: 0.5, damping: 0.95)

    public init(stiffness: CGFloat = 0.12, damping: CGFloat = 0.85) {
        self.stiffness = stiffness
        self.damping = damping
    }

    /// Update position with spring physics
    /// - Parameters:
    ///   - current: Current position
    ///   - target: Target position
    ///   - deltaTime: Time since last update
    /// - Returns: New position
    public mutating func update(current: CGPoint, target: CGPoint, deltaTime: CGFloat) -> CGPoint {
        let displacement = CGPoint(
            x: target.x - current.x,
            y: target.y - current.y
        )

        // Spring force: F = -k * displacement
        let springForce = CGPoint(
            x: displacement.x * stiffness,
            y: displacement.y * stiffness
        )

        // Apply spring force and damping
        velocity.x = velocity.x * damping + springForce.x
        velocity.y = velocity.y * damping + springForce.y

        // Update position
        return CGPoint(
            x: current.x + velocity.x,
            y: current.y + velocity.y
        )
    }

    /// Check if animation has settled (velocity near zero)
    public func isSettled(threshold: CGFloat = 0.1) -> Bool {
        return abs(velocity.x) < threshold && abs(velocity.y) < threshold
    }
}

// MARK: - Floating Window Configuration

/// Configuration for the floating counter window
public struct FloatingWindowConfig {
    /// Window size
    public var windowSize: CGSize = CGSize(width: 100, height: 36)

    /// Offset from cursor
    public var cursorOffset: CGPoint = CGPoint(x: 20, y: 20)

    /// Margin from screen edges
    public var edgeMargin: CGFloat = 20

    /// Menubar avoidance height
    public var menubarHeight: CGFloat = 24

    /// Spring physics tuning
    public var springPhysics: SpringPhysics = .default

    /// Target frame rate (for energy efficiency)
    public var targetFrameRate: Int = 30

    public static let `default` = FloatingWindowConfig()
}

// MARK: - Floating Counter Window

/// Borderless, transparent floating window that follows cursor with spring physics
/// Energy-efficient using display link and respects accessibility settings
public final class FloatingCounterWindow: NSPanel {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.sight.ui", category: "FloatingWindow")

    /// Configuration
    public var config: FloatingWindowConfig {
        didSet { updateForConfig() }
    }

    /// Current target position (cursor + offset)
    private var targetPosition: CGPoint = .zero

    /// Spring physics engine
    private var physics: SpringPhysics

    /// Display link for physics updates
    private var displayLink: CVDisplayLink?

    /// Global mouse event monitor
    private var mouseMonitor: Any?

    /// Timer for fallback updates when display link unavailable
    private var fallbackTimer: Timer?

    /// Low power mode observer
    private var lowPowerObserver: NSObjectProtocol?

    /// Focus mode observer
    private var focusObserver: NSObjectProtocol?

    /// Whether window is actively tracking
    private var isTracking = false

    /// Whether in low power mode
    private var isLowPowerMode = false

    /// Static corner position for low power mode
    private var staticCornerPosition: CGPoint?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// SECURITY: Flag to prevent CVDisplayLink callbacks after deallocation
    private var displayLinkActive = false

    // MARK: - Initialization

    public init(config: FloatingWindowConfig = .default) {
        self.config = config
        self.physics = config.springPhysics

        super.init(
            contentRect: NSRect(origin: .zero, size: config.windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupAccessibility()
        setupObservers()

        logger.info("FloatingCounterWindow initialized")
    }

    deinit {
        // SECURITY: Mark display link as inactive BEFORE stopping to prevent race
        displayLinkActive = false
        stopTracking()
        removeObservers()
    }

    // MARK: - Setup

    private func setupWindow() {
        // Transparent, borderless, floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovableByWindowBackground = false

        // Accept mouse events but don't activate
        acceptsMouseMovedEvents = false
        ignoresMouseEvents = true

        // Appearance follows system
        if #available(macOS 14.0, *) {
            appearance = nil  // Inherit from system
        }
    }

    private func setupAccessibility() {
        // Check for Reduce Motion preference
        updateForReduceMotion()

        // Observe preference changes
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.ReduceMotionStatusDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateForReduceMotion()
        }
    }

    private func updateForReduceMotion() {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if reduceMotion {
            physics = .reducedMotion
            logger.info("Reduce Motion enabled - using simplified physics")
        } else {
            physics = config.springPhysics
        }
    }

    private func setupObservers() {
        // Low power mode
        lowPowerObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateForPowerState()
        }

        // Screen configuration changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateStaticCornerPosition()
        }

        // Fullscreen app changes
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateVisibilityForContext()
        }

        // Focus mode (Do Not Disturb)
        if #available(macOS 12.0, *) {
            // Check for Focus mode by observing notification center status
            // Note: Direct API requires entitlements, so we check indirectly
        }
    }

    private func removeObservers() {
        if let observer = lowPowerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = focusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func updateForConfig() {
        setContentSize(config.windowSize)
        physics = config.springPhysics
    }

    private func updateForPowerState() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        if isLowPowerMode {
            logger.info("Low power mode - switching to static corner position")
            stopDisplayLink()
            moveToStaticCorner()
        } else {
            logger.info("Normal power mode - resuming cursor tracking")
            if isTracking {
                startDisplayLink()
            }
        }
    }

    private func updateStaticCornerPosition() {
        guard let screen = NSScreen.main else { return }

        // Bottom-right corner with margin
        staticCornerPosition = CGPoint(
            x: screen.visibleFrame.maxX - config.windowSize.width - config.edgeMargin,
            y: screen.visibleFrame.minY + config.edgeMargin
        )
    }

    private func moveToStaticCorner() {
        updateStaticCornerPosition()

        if let position = staticCornerPosition {
            setFrameOrigin(position)
        }
    }

    // MARK: - Visibility Logic

    private func updateVisibilityForContext() {
        let shouldHide = shouldAutoHide()

        if shouldHide {
            orderOut(nil)
        } else if isTracking {
            orderFront(nil)
        }
    }

    /// Determine if window should auto-hide based on context
    public func shouldAutoHide() -> Bool {
        // Check fullscreen
        if isInFullscreenApp() {
            return true
        }

        // Check cursor near menubar
        if isCursorNearMenubar() {
            return true
        }

        // Check Do Not Disturb / Focus mode
        if isDoNotDisturbEnabled() {
            return true
        }

        return false
    }

    private func isInFullscreenApp() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        // Check if any window of the app is fullscreen
        // Use CGWindowListCopyWindowInfo for accurate detection
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard
            let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return false
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                ownerPID == frontApp.processIdentifier,
                let bounds = window[kCGWindowBounds as String] as? [String: CGFloat]
            else {
                continue
            }

            // Check if window fills entire screen
            if let screen = NSScreen.main {
                let windowFrame = CGRect(
                    x: bounds["X"] ?? 0,
                    y: bounds["Y"] ?? 0,
                    width: bounds["Width"] ?? 0,
                    height: bounds["Height"] ?? 0
                )

                if windowFrame.size == screen.frame.size {
                    return true
                }
            }
        }

        return false
    }

    private func isCursorNearMenubar() -> Bool {
        let cursorLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return false }

        let menubarZone = screen.frame.maxY - config.menubarHeight
        return cursorLocation.y >= menubarZone
    }

    private func isDoNotDisturbEnabled() -> Bool {
        // Check Do Not Disturb via defaults
        // Note: This is a heuristic as direct API requires entitlements
        let dndDefaults = UserDefaults(suiteName: "com.apple.ncprefs")
        return dndDefaults?.bool(forKey: "doNotDisturb") ?? false
    }

    // MARK: - Tracking Control

    /// Start tracking cursor movement
    public func startTracking() {
        guard !isTracking else { return }

        isTracking = true
        logger.info("Starting cursor tracking")

        // Start mouse event monitoring
        startMouseMonitor()

        // Start display link for physics updates
        if !isLowPowerMode {
            startDisplayLink()
        } else {
            moveToStaticCorner()
        }

        updateVisibilityForContext()
        if !shouldAutoHide() {
            orderFront(nil)
        }
    }

    /// Stop tracking cursor movement
    public func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        logger.info("Stopping cursor tracking")

        stopMouseMonitor()
        stopDisplayLink()
        stopFallbackTimer()
        orderOut(nil)
    }

    // MARK: - Mouse Monitoring

    private func startMouseMonitor() {
        // Global mouse moved event monitor
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) {
            [weak self] event in
            self?.handleMouseMoved(event)
        }
    }

    private func stopMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    private func handleMouseMoved(_ event: NSEvent) {
        guard isTracking, !isLowPowerMode else { return }

        let cursorLocation = NSEvent.mouseLocation

        // Update target position with offset
        targetPosition = CGPoint(
            x: cursorLocation.x + config.cursorOffset.x,
            y: cursorLocation.y + config.cursorOffset.y
        )

        // Clamp to screen bounds
        clampTargetToScreen()

        // Update visibility
        updateVisibilityForContext()
    }

    private func clampTargetToScreen() {
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let windowSize = config.windowSize
        let margin = config.edgeMargin

        targetPosition.x = max(
            visibleFrame.minX + margin,
            min(targetPosition.x, visibleFrame.maxX - windowSize.width - margin)
        )

        targetPosition.y = max(
            visibleFrame.minY + margin,
            min(
                targetPosition.y,
                visibleFrame.maxY - windowSize.height - margin - config.menubarHeight)
        )
    }

    // MARK: - Display Link (CVDisplayLink for macOS)

    private func startDisplayLink() {
        guard displayLink == nil else { return }

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else {
            logger.warning("Failed to create CVDisplayLink, using fallback timer")
            startFallbackTimer()
            return
        }

        self.displayLink = displayLink

        // SECURITY: Mark as active before starting
        displayLinkActive = true

        // Set up callback with weak self capture pattern
        // We use a class wrapper to safely check if window is still valid
        let outputCallback: CVDisplayLinkOutputCallback = {
            displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext -> CVReturn in

            guard let context = displayLinkContext else { return kCVReturnSuccess }

            // SECURITY: Get unretained reference but immediately dispatch to main
            // where we'll check the active flag
            let window = Unmanaged<FloatingCounterWindow>.fromOpaque(context).takeUnretainedValue()

            // Check if still active before dispatching
            guard window.displayLinkActive else { return kCVReturnSuccess }

            DispatchQueue.main.async { [weak window] in
                // Double-check: use weak reference in async block
                guard let window = window, window.displayLinkActive else { return }
                window.updatePhysics()
            }

            return kCVReturnSuccess
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, outputCallback, selfPointer)

        // Start the display link
        CVDisplayLinkStart(displayLink)

        logger.info("CVDisplayLink started")
    }

    private func stopDisplayLink() {
        // SECURITY: Mark as inactive BEFORE stopping to prevent race
        displayLinkActive = false

        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }
    }

    private func startFallbackTimer() {
        let interval = 1.0 / Double(config.targetFrameRate)
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            self?.updatePhysics()
        }
    }

    private func stopFallbackTimer() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    // MARK: - Physics Update

    private func updatePhysics() {
        guard isTracking, !isLowPowerMode, !shouldAutoHide() else { return }

        let currentOrigin = frame.origin

        // Apply spring physics
        let newPosition = physics.update(
            current: currentOrigin,
            target: targetPosition,
            deltaTime: 1.0 / CGFloat(config.targetFrameRate)
        )

        // Only update if position changed significantly
        let threshold: CGFloat = 0.5
        if abs(newPosition.x - currentOrigin.x) > threshold
            || abs(newPosition.y - currentOrigin.y) > threshold
        {
            setFrameOrigin(newPosition)
        }
    }

    // MARK: - Public API

    /// Update the content view
    public func setContent(_ view: NSView) {
        contentView = view
    }

    /// Show the floating window
    public func show() {
        startTracking()
    }

    /// Hide the floating window
    public func hide() {
        stopTracking()
    }

    /// Update spring physics parameters
    public func updateSpringParameters(stiffness: CGFloat, damping: CGFloat) {
        config.springPhysics = SpringPhysics(stiffness: stiffness, damping: damping)
        physics = config.springPhysics
    }
}

// MARK: - Position Logic (Testable)

/// Pure functions for position calculations (unit testable)
public struct FloatingWindowPositionLogic {

    /// Calculate target position from cursor location
    public static func targetPosition(
        cursorLocation: CGPoint,
        offset: CGPoint
    ) -> CGPoint {
        return CGPoint(
            x: cursorLocation.x + offset.x,
            y: cursorLocation.y + offset.y
        )
    }

    /// Clamp position to visible screen area
    public static func clampToScreen(
        position: CGPoint,
        windowSize: CGSize,
        visibleFrame: CGRect,
        margin: CGFloat,
        menubarHeight: CGFloat
    ) -> CGPoint {
        var clamped = position

        clamped.x = max(
            visibleFrame.minX + margin,
            min(clamped.x, visibleFrame.maxX - windowSize.width - margin)
        )

        clamped.y = max(
            visibleFrame.minY + margin,
            min(clamped.y, visibleFrame.maxY - windowSize.height - margin - menubarHeight)
        )

        return clamped
    }

    /// Check if cursor is in menubar zone
    public static func isCursorInMenubarZone(
        cursorY: CGFloat,
        screenMaxY: CGFloat,
        menubarHeight: CGFloat
    ) -> Bool {
        return cursorY >= (screenMaxY - menubarHeight)
    }

    /// Calculate static corner position
    public static func staticCornerPosition(
        visibleFrame: CGRect,
        windowSize: CGSize,
        margin: CGFloat
    ) -> CGPoint {
        return CGPoint(
            x: visibleFrame.maxX - windowSize.width - margin,
            y: visibleFrame.minY + margin
        )
    }
}
