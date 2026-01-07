import Foundation
import ServiceManagement
import os.log

/// Manages Launch at Login functionality
/// Uses LaunchAgent for ad-hoc signed apps (SMAppService requires Developer ID signing)
public final class LoginItemManager {

    public static let shared = LoginItemManager()

    private let logger = Logger(subsystem: "com.kumargaurav.Sight.app", category: "LoginItem")

    /// LaunchAgent plist path
    private var launchAgentPath: URL {
        let libraryPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("LaunchAgents")
        return libraryPath.appendingPathComponent("com.kumargaurav.Sight.plist")
    }

    /// Whether launch at login is currently enabled
    public var isEnabled: Bool {
        get {
            // Check if LaunchAgent plist exists
            return FileManager.default.fileExists(atPath: launchAgentPath.path)
        }
        set {
            setEnabled(newValue)
        }
    }

    /// Enable or disable launch at login
    public func setEnabled(_ enabled: Bool) {
        logger.info("Setting Launch at Login: \(enabled)")

        // Save preference
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")

        if enabled {
            createLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }

    /// Create LaunchAgent plist for auto-start
    private func createLaunchAgent() {
        // Get the app path - prefer installed location over dev location
        var appPath = Bundle.main.bundlePath

        // If running from build directory, use the expected Applications path
        if appPath.contains(".build/") || appPath.contains("/build/") {
            let installedPath = "/Applications/Sight.app"
            if FileManager.default.fileExists(atPath: installedPath) {
                appPath = installedPath
                logger.info("Using installed app path: \(appPath)")
            } else {
                logger.warning(
                    "App not installed in /Applications - LaunchAgent may not work correctly")
            }
        }

        // Ensure LaunchAgents directory exists
        let launchAgentsDir = launchAgentPath.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(
                at: launchAgentsDir, withIntermediateDirectories: true)
        } catch {
            logger.error("Could not create LaunchAgents directory: \(error.localizedDescription)")
            return
        }

        // Create plist content with open command for better reliability
        let plistContent: [String: Any] = [
            "Label": "com.kumargaurav.Sight",
            "ProgramArguments": ["/usr/bin/open", "-a", appPath],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua",  // Only load in GUI sessions
        ]

        // Write plist
        do {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: plistContent,
                format: .xml,
                options: 0
            )
            try plistData.write(to: launchAgentPath)
            logger.info("✓ LaunchAgent created at: \(self.launchAgentPath.path)")
            logger.info("  App path: \(appPath)")

            // Load the agent immediately
            loadLaunchAgent()

        } catch {
            logger.error("Failed to create LaunchAgent: \(error.localizedDescription)")
        }
    }

    /// Remove LaunchAgent plist
    private func removeLaunchAgent() {
        // Unload first
        unloadLaunchAgent()

        // Remove plist file
        do {
            if FileManager.default.fileExists(atPath: launchAgentPath.path) {
                try FileManager.default.removeItem(at: launchAgentPath)
                logger.info("✓ LaunchAgent removed")
            }
        } catch {
            logger.error("Failed to remove LaunchAgent: \(error.localizedDescription)")
        }
    }

    /// Load the LaunchAgent using launchctl
    private func loadLaunchAgent() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", launchAgentPath.path]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                logger.info("✓ LaunchAgent loaded")
            } else {
                logger.warning("LaunchAgent load returned status: \(process.terminationStatus)")
            }
        } catch {
            logger.error("Failed to load LaunchAgent: \(error.localizedDescription)")
        }
    }

    /// Unload the LaunchAgent using launchctl
    private func unloadLaunchAgent() {
        guard FileManager.default.fileExists(atPath: launchAgentPath.path) else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", launchAgentPath.path]

        do {
            try process.run()
            process.waitUntilExit()
            logger.info("✓ LaunchAgent unloaded")
        } catch {
            logger.error("Failed to unload LaunchAgent: \(error.localizedDescription)")
        }
    }

    /// Sync with preferences on app launch
    public func syncWithPreferences(_ preferences: PreferencesManager) {
        let prefEnabled = preferences.launchAtLogin
        let actualEnabled = isEnabled

        if prefEnabled != actualEnabled {
            logger.info(
                "Syncing Launch at Login: preference=\(prefEnabled), actual=\(actualEnabled)")
            if prefEnabled {
                // User wants it enabled, but LaunchAgent doesn't exist
                setEnabled(true)
            } else {
                // User wants it disabled
                setEnabled(false)
            }
        }
    }

    /// Get human-readable status for UI
    public var statusDescription: String {
        if isEnabled {
            return "Enabled (LaunchAgent)"
        } else {
            return "Disabled"
        }
    }
}
