import AppKit
import Combine
import Foundation
import os.log

// MARK: - Idle Detector

/// Detects user idle time to pause/reset timer
public final class IdleDetector: ObservableObject {
    public static let shared = IdleDetector()

    @Published public private(set) var isIdle: Bool = false
    @Published public private(set) var idleSeconds: Int = 0

    private var checkTimer: Timer?
    private let logger = Logger(subsystem: "com.sight.app", category: "IdleDetector")

    public var onIdlePause: (() -> Void)?
    public var onIdleResume: (() -> Void)?
    public var onIdleReset: (() -> Void)?

    private init() {}

    deinit {
        stop()
    }

    // MARK: - Public API

    public func start() {
        guard checkTimer == nil else { return }

        logger.info("Starting idle detection")

        // Check every 10 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdleTime()
        }
    }

    public func stop() {
        checkTimer?.invalidate()
        checkTimer = nil
        isIdle = false
        idleSeconds = 0
    }

    // MARK: - Detection

    private func checkIdleTime() {
        // Get system idle time using IOKit - check multiple input types
        let mouseMovedIdle = Int(
            CGEventSource.secondsSinceLastEventType(
                .hidSystemState,
                eventType: .mouseMoved
            ))

        let keyboardIdle = Int(
            CGEventSource.secondsSinceLastEventType(
                .hidSystemState,
                eventType: .keyDown
            ))

        let mouseClickIdle = Int(
            CGEventSource.secondsSinceLastEventType(
                .hidSystemState,
                eventType: .leftMouseDown
            ))

        let scrollWheelIdle = Int(
            CGEventSource.secondsSinceLastEventType(
                .hidSystemState,
                eventType: .scrollWheel
            ))

        // Use the smallest value (most recent activity)
        idleSeconds = min(mouseMovedIdle, keyboardIdle, mouseClickIdle, scrollWheelIdle)

        let pauseThreshold = PreferencesManager.shared.idlePauseMinutes * 60
        let resetThreshold = PreferencesManager.shared.idleResetMinutes * 60

        // SECURITY: Ensure reset threshold is always >= pause threshold to prevent logic issues
        // If pauseThreshold is 0 (disabled), we still want reset to work if resetThreshold is set
        let effectiveResetThreshold = max(resetThreshold, pauseThreshold)

        // Check for reset first (long idle)
        if idleSeconds >= effectiveResetThreshold && effectiveResetThreshold > 0 {
            // User away for long time - reset timer
            // Note: Reset is called even if pause wasn't triggered (pauseThreshold could be 0)
            if !isIdle || idleSeconds >= effectiveResetThreshold {
                logger.info("Idle reset after \(self.idleSeconds)s")
                isIdle = true
                onIdleReset?()
            }
        } else if idleSeconds >= pauseThreshold && pauseThreshold > 0 {
            // User is idle - pause timer (only if pause is enabled)
            if !isIdle {
                logger.info("User idle for \(self.idleSeconds)s - pausing")
                isIdle = true
                onIdlePause?()
            }
        } else if isIdle && idleSeconds < 10 {
            // User is back (detected activity within 10 seconds)
            logger.info("User returned from idle")
            isIdle = false
            onIdleResume?()
        }
    }
}
