import AppKit
import Foundation
import UserNotifications
import os.log

/// Main Renderer client with automatic transport selection and fallback
public final class Renderer: RendererAPI {

    // MARK: - Singleton

    public static let shared = Renderer()

    // MARK: - Properties

    private var transport: RendererAPI?
    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "Renderer")
    private let fallback = FallbackRenderer()

    /// Transport type currently in use
    public enum TransportType {
        case xpc
        case socket
        case fallback
    }

    public private(set) var currentTransport: TransportType = .fallback

    public var isAvailable: Bool {
        transport?.isAvailable ?? false
    }

    // MARK: - Initialization

    private init() {
        selectTransport()
    }

    // MARK: - Transport Selection

    private func selectTransport() {
        // Force fallback for now since we are running as a standalone executable in dev
        logger.info("Forcing fallback renderer for standalone execution")
        self.transport = nil
        self.currentTransport = .fallback

        /*
        // Try XPC first (production)
        let xpc = XPCRendererClient()
        if xpc.isAvailable {
            transport = xpc
            currentTransport = .xpc
            logger.info("Using XPC transport")
            return
        }
        
        // Try socket (development)
        let socket = SocketRendererClient()
        // Give socket time to connect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if socket.isAvailable {
                self?.transport = socket
                self?.currentTransport = .socket
                self?.logger.info("Using socket transport")
            } else {
                self?.transport = nil
                self?.currentTransport = .fallback
                self?.logger.warning("No renderer available, using fallback")
            }
        }
        */
    }

    /// Force a specific transport (for testing)
    public func useTransport(_ type: TransportType) {
        switch type {
        case .xpc:
            transport = XPCRendererClient()
        case .socket:
            transport = SocketRendererClient()
        case .fallback:
            transport = nil
        }
        currentTransport = type
    }

    // MARK: - RendererAPI

    public func showPreBreak(preSeconds: Int) {
        if let transport = transport, transport.isAvailable {
            transport.showPreBreak(preSeconds: preSeconds)
        } else {
            logger.info("Fallback: showPreBreak(\(preSeconds))")
            fallback.showPreBreak(preSeconds: preSeconds)
        }
    }

    public func showBreak(duration: Int, style: BreakStyle) {
        if let transport = transport, transport.isAvailable {
            transport.showBreak(duration: duration, style: style)
        } else {
            logger.info("Fallback: showBreak(\(duration), \(style.rawValue))")
            fallback.showBreak(duration: duration, style: style)
        }
    }

    public func showFloatingCounter(params: FloatingCounterParams) {
        if let transport = transport, transport.isAvailable {
            transport.showFloatingCounter(params: params)
        } else {
            // Floating counter not supported in fallback
            logger.debug("Floating counter not available in fallback mode")
        }
    }

    public func showNudge(type: NudgeType) {
        if let transport = transport, transport.isAvailable {
            transport.showNudge(type: type)
        } else {
            logger.info("Fallback: showNudge(\(type.rawValue))")
            fallback.showNudge(type: type)
        }
    }

    public func showOvertimeNudge(elapsedMinutes: Int) {
        logger.info("Fallback: showOvertimeNudge(\(elapsedMinutes) min)")
        fallback.showOvertimeNudge(elapsedMinutes: elapsedMinutes)
    }

    public func updateCountdown(remainingSeconds: Int) {
        transport?.updateCountdown(remainingSeconds: remainingSeconds)
    }

    public func hide() {
        if let transport = transport, transport.isAvailable {
            transport.hide()
        } else {
            fallback.hide()
        }
    }

    // MARK: - Static Convenience Methods

    /// Show pre-break warning (static convenience)
    public static func showPreBreak(preSeconds: Int) {
        shared.showPreBreak(preSeconds: preSeconds)
    }

    /// Show break overlay (static convenience)
    public static func showBreak(durationSeconds: Int) {
        shared.showBreak(duration: durationSeconds, style: .calm)
    }

    /// Show a micro-nudge (static convenience)
    public static func showNudge(type: NudgeType) {
        shared.showNudge(type: type)
    }

    /// Hide overlay (static convenience)
    public static func hideOverlay() {
        shared.hide()
    }

    /// Show overtime nudge (static convenience)
    public static func showOvertimeNudge(elapsedMinutes: Int) {
        shared.showOvertimeNudge(elapsedMinutes: elapsedMinutes)
    }
}

// MARK: - Fallback Renderer

/// Native macOS fallback when Anigravity renderer is unavailable
/// Uses NSAlert for breaks and UserNotifications for pre-break warnings
final class FallbackRenderer: RendererAPI {

    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "Fallback")
    private var alertWindow: NSWindow?
    private var notificationAuthorized = false

    var isAvailable: Bool { true }

    init() {
        // Request notification authorization on init
        requestNotificationAuthorization()
    }

    private func requestNotificationAuthorization() {
        // Skip notification setup if we're running without a bundle ID (dev mode)
        guard Bundle.main.bundleIdentifier != nil else {
            logger.warning("Running without bundle ID - notifications disabled")
            notificationAuthorized = false
            return
        }

        DispatchQueue.main.async {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
                [weak self] granted, error in
                self?.notificationAuthorized = granted
                if let error = error {
                    self?.logger.error("Notification auth error: \(error.localizedDescription)")
                } else {
                    self?.logger.info("Notification authorization: \(granted)")
                }
            }
        }
    }

    func showPreBreak(preSeconds: Int) {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showPreBreak(preSeconds: preSeconds)
            }
            return
        }

        // If notifications aren't authorized, use a simple alert instead
        guard notificationAuthorized else {
            logger.warning("Notifications not authorized, showing alert instead")
            showPreBreakAlert(preSeconds: preSeconds)
            return
        }

        // Show system notification
        let content = UNMutableNotificationContent()
        content.title = "Break Coming Up"
        content.body = "Take a break in \(preSeconds) seconds"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "sight.prebreak",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to show notification: \(error.localizedDescription)")
                // Fallback to alert on error
                DispatchQueue.main.async {
                    self?.showPreBreakAlert(preSeconds: preSeconds)
                }
            }
        }

        logger.info("Fallback: Pre-break notification sent")
    }

    private func showPreBreakAlert(preSeconds: Int) {
        // Pre-break alert disabled - just log
        logger.info("Pre-break: \(preSeconds)s until break")
    }

    func showBreak(duration: Int, style: BreakStyle) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showBreak(duration: duration, style: style)
            }
            return
        }

        // Use the new beautiful fullscreen overlay
        BreakOverlayManager.shared.show(duration: duration, style: style)

        logger.info("Fallback: Break overlay shown for \(duration)s")
    }

    func showFloatingCounter(params: FloatingCounterParams) {
        // Not supported in fallback - overlay has its own counter
    }

    func showNudge(type: NudgeType) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showNudge(type: type)
            }
            return
        }

        NudgeOverlayWindowController.shared.showNudge(type: type)
        logger.info("Fallback: Nudge \(type.rawValue) shown")
    }

    func showOvertimeNudge(elapsedMinutes: Int) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showOvertimeNudge(elapsedMinutes: elapsedMinutes)
            }
            return
        }

        NudgeOverlayWindowController.shared.showOvertimeNudge(elapsedMinutes: elapsedMinutes)
        logger.info("Fallback: Overtime nudge shown (\(elapsedMinutes) min)")
    }

    func updateCountdown(remainingSeconds: Int) {
        // Not supported in fallback - overlay handles its own countdown
    }

    func hide() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.hide()
            }
            return
        }

        BreakOverlayManager.shared.hide()
        NudgeOverlayWindowController.shared.hide()

        alertWindow?.close()
        alertWindow = nil
    }
}
