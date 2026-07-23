import AppKit
import Combine
import Foundation
import os.log

extension TimerStateMachine {

    // MARK: - System Observers

    internal func setupSystemObservers() {
        // Wake from sleep - resume timer if needed
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // SECURITY: Dispatch to MainActor for thread safety
            Task { @MainActor in
                self?.handleSystemWake()
            }
        }

        // Sleep - pause timer
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // SECURITY: Dispatch to MainActor for thread safety
            Task { @MainActor in
                self?.handleSystemSleep()
            }
        }
    }

    internal func removeSystemObservers() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    internal func handleSystemWake() {
        logger.info("System wake detected")

        // Only resume if WE (system sleep) were the one who paused it
        // Don't resume if user manually paused or if smart pause paused
        if isPaused && pauseSource == .system && currentState != .idle {
            logger.info("Resuming timer after system wake")
            resume()
        } else if isPaused && pauseSource != .system {
            logger.info(
                "Timer paused by \(self.pauseSource?.rawValue ?? "unknown") - not resuming on wake")
        }
    }

    internal func handleSystemSleep() {
        logger.info("System sleep detected")

        // Only pause if timer is running (not already paused)
        // Mark this as a system pause so we know to resume on wake
        if currentState != .idle && !isPaused {
            logger.info("Pausing timer for system sleep")
            pause(source: .system)
        }
    }


}
