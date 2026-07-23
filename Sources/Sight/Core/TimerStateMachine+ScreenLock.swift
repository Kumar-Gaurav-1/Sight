import AppKit
import Combine
import Foundation
import os.log

extension TimerStateMachine {

    // MARK: - Screen Lock

    /// Lock the screen to force user to step away during break
    internal func lockScreen() {
        logger.info("Locking screen for break")

        // Use the SACLockScreenImmediate function via session services
        // This is the most reliable method on modern macOS
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]

        do {
            try task.run()
            logger.debug("Screen lock command executed")
        } catch {
            // Fallback: Try using Keychain menu bar lock
            logger.warning("pmset failed, trying alternate method: \\(error.localizedDescription)")

            // Use AppleScript as fallback (works on all macOS versions)
            let script = NSAppleScript(
                source: """
                        tell application "System Events" to keystroke "q" using {control down, command down}
                    """)
            var scriptError: NSDictionary?
            script?.executeAndReturnError(&scriptError)

            if scriptError != nil {
                logger.error("Screen lock AppleScript failed")
            }
        }
    }

}
