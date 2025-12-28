import SwiftUI
import AppKit
import os.log

// MARK: - Nudge Overlay Controller

public final class NudgeOverlayWindowController: NSObject {
    private var window: NSWindow?
    private var hideTimer: Timer?
    private let logger = Logger(subsystem: "com.sight.ui", category: "NudgeOverlay")
    
    public static let shared = NudgeOverlayWindowController()
    
    private override init() {
        super.init()
    }
    
    public func showNudge(type: NudgeType, duration: TimeInterval = 5.0) {
        // Create window if needed (lazy init)
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        
        // Update content based on type
        switch type {
        case .posture:
            window.contentView = NSHostingView(rootView: PostureNudgeView())
        case .blink:
            window.contentView = NSHostingView(rootView: BlinkNudgeView())
        case .miniExercise:
            // Placeholder: Use Posture view for now until Exercise view is built
            window.contentView = NSHostingView(rootView: PostureNudgeView())
        }
        
        // Ensure visible
        window.alphaValue = 0
        window.orderFront(nil) // Don't steal focus (makeKey) for nudges
        
        // Position at top-right or center (let's do top-center for visibility)
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenRect.midX - (windowSize.width / 2)
            let y = screenRect.maxY - windowSize.height - 40 // Padding from top
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Animate in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().alphaValue = 1.0
        }
        
        // Schedule dismissal
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    public func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        
        guard let window = window else { return }
        
        // Smooth exit animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
        }
    }
    
    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 140), // Slightly larger than view
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false // Allow interaction if we add buttons later
        
        // Content view set in showNudge
        
        self.window = window
    }
}
