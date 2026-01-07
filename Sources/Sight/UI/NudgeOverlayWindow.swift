import AppKit
import SwiftUI
import os.log

// MARK: - Nudge Overlay Controller

public final class NudgeOverlayWindowController: NSObject {
    private var window: NSWindow?
    private var dimWindow: NSWindow?
    private var hideTimer: Timer?
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.ui", category: "NudgeOverlay")

    public static let shared = NudgeOverlayWindowController()

    private override init() {
        super.init()
    }

    public func showNudge(type: NudgeType, duration: TimeInterval = 5.0) {
        logger.info("showNudge called for type: \(type.rawValue)")

        // Close existing window to ensure fresh size
        window?.close()
        window = nil

        // Show dim overlay if enabled in preferences
        if PreferencesManager.shared.dimScreenOnReminder {
            showDimOverlay()
        }

        // Fixed window size
        let windowSize = NSSize(width: 400, height: 80)

        // Create panel (better for floating overlays)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary,
        ]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false

        self.window = panel

        logger.info("Panel created with size: \(windowSize.width)x\(windowSize.height)")

        // Create the SwiftUI view with dismiss callback
        let swiftUIView: AnyView
        switch type {
        case .posture:
            swiftUIView = AnyView(PostureNudgeView(onDismiss: { [weak self] in self?.hide() }))
        case .blink:
            swiftUIView = AnyView(BlinkNudgeView(onDismiss: { [weak self] in self?.hide() }))
        case .miniExercise:
            swiftUIView = AnyView(MiniExerciseNudgeView(onDismiss: { [weak self] in self?.hide() }))
        }

        // Create hosting view and set it up
        let hostingView = NSHostingView(rootView: swiftUIView)
        hostingView.frame = NSRect(origin: .zero, size: windowSize)
        hostingView.autoresizingMask = [.width, .height]

        // Set content view
        panel.contentView = hostingView

        logger.info("Hosting view frame: \(NSStringFromRect(hostingView.frame))")

        // Position at top-center of screen containing mouse cursor (multi-monitor support)
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen =
            NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        if let screen = targetScreen {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (windowSize.width / 2)
            let finalY = screenRect.maxY - windowSize.height - 40  // Final position

            logger.info("Positioning at x=\(x), y=\(finalY)")

            // Set final position directly (no animation for debugging)
            panel.setFrame(
                NSRect(x: x, y: finalY, width: windowSize.width, height: windowSize.height),
                display: true)
            panel.orderFront(nil)

            logger.info("Panel final frame: \(NSStringFromRect(panel.frame))")
        }

        // Schedule dismissal
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) {
            [weak self] _ in
            self?.hide()
        }
    }

    public func showOvertimeNudge(elapsedMinutes: Int, duration: TimeInterval = 8.0) {
        logger.info("showOvertimeNudge called for \(elapsedMinutes) minutes")

        // Close existing window to ensure fresh size
        window?.close()
        window = nil

        // Show dim overlay if enabled in preferences
        if PreferencesManager.shared.dimScreenOnReminder {
            showDimOverlay()
        }

        // Fixed window size
        let windowSize = NSSize(width: 400, height: 80)

        // Create panel (consistent with showNudge)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary,
        ]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false

        self.window = panel

        // Create hosting view with dismiss callback
        let hostingView = NSHostingView(
            rootView: OvertimeNudgeView(
                elapsedMinutes: elapsedMinutes,
                onDismiss: { [weak self] in self?.hide() }
            )
        )
        hostingView.frame = NSRect(origin: .zero, size: windowSize)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        // Position at top-center of screen containing mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen =
            NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        if let screen = targetScreen {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (windowSize.width / 2)
            let finalY = screenRect.maxY - windowSize.height - 40

            // Set position and show
            panel.setFrame(
                NSRect(x: x, y: finalY, width: windowSize.width, height: windowSize.height),
                display: true)
            panel.orderFront(nil)

            logger.info("Panel final frame: \(NSStringFromRect(panel.frame))")
        }

        // Schedule dismissal
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) {
            [weak self] _ in
            self?.hide()
        }
    }

    public func hide() {
        hideTimer?.invalidate()
        hideTimer = nil

        // Hide dim overlay immediately (fixes stuck dim bug)
        hideDimOverlay()

        guard let window = window else { return }

        // Get current position and calculate exit position
        let currentOrigin = window.frame.origin
        let exitY = currentOrigin.y + 80  // Slide up

        // Smooth slide-up exit animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            window.animator().setFrameOrigin(NSPoint(x: currentOrigin.x, y: exitY))
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
        }
    }

    // MARK: - Dim Overlay

    private func showDimOverlay() {
        // Create dim window if needed
        if dimWindow == nil {
            createDimWindow()
        }

        guard let dimWindow = dimWindow else { return }

        // Position to cover all screens
        let fullRect = NSScreen.screens.reduce(NSRect.zero) { result, screen in
            result.union(screen.frame)
        }
        dimWindow.setFrame(fullRect, display: true)

        dimWindow.alphaValue = 0
        dimWindow.orderFront(nil)

        // Animate dim in (use preference for intensity, default 0.5)
        let dimIntensity = PreferencesManager.shared.nudgeDimIntensity
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            dimWindow.animator().alphaValue = dimIntensity
        }

        logger.debug("Dim overlay shown")
    }

    private func hideDimOverlay() {
        guard let dimWindow = dimWindow else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            dimWindow.animator().alphaValue = 0
        } completionHandler: {
            dimWindow.orderOut(nil)
        }

        logger.debug("Dim overlay hidden")
    }

    private func createDimWindow() {
        let dimWindow = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        dimWindow.level = .floating - 1  // Just below the nudge window
        dimWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        dimWindow.isOpaque = false
        dimWindow.backgroundColor = NSColor.black
        dimWindow.ignoresMouseEvents = true  // Click-through

        self.dimWindow = dimWindow
    }

    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 100),  // Wide enough for nudge content
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .statusBar  // Higher than .floating to appear over fullscreen apps
        window.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary,
        ]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false  // Allow interaction if we add buttons later

        // Content view set in showNudge

        self.window = window
    }
}
