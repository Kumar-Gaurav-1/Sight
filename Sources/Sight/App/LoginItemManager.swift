import Foundation
import ServiceManagement
import os.log

/// Manages Launch at Login functionality using modern SMAppService
public final class LoginItemManager {

    public static let shared = LoginItemManager()

    private let logger = Logger(subsystem: "com.kumargaurav.Sight.app", category: "LoginItem")

    /// Whether launch at login is currently enabled
    public var isEnabled: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
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

        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
                logger.info("✓ Launch at Login enabled via SMAppService")
            } else {
                if SMAppService.mainApp.status == .notRegistered { return }
                try SMAppService.mainApp.unregister()
                logger.info("✓ Launch at Login disabled via SMAppService")
            }
        } catch {
            logger.error("Failed to update Launch at Login status: \(error.localizedDescription)")
        }
    }

    /// Clean up old plist-based LaunchAgent
    private func cleanupLegacyLaunchAgent() {
        let libraryPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("LaunchAgents")
        let legacyPath = libraryPath.appendingPathComponent("com.kumargaurav.Sight.plist")

        if FileManager.default.fileExists(atPath: legacyPath.path) {
            do {
                try FileManager.default.removeItem(at: legacyPath)
                logger.info("✓ Legacy LaunchAgent cleaned up")
            } catch {
                logger.error("Failed to clean up legacy LaunchAgent: \(error.localizedDescription)")
            }
        }
    }

    /// Sync with preferences on app launch
    public func syncWithPreferences(_ preferences: PreferencesManager) {
        let prefEnabled = preferences.launchAtLogin
        let actualEnabled = isEnabled

        if prefEnabled != actualEnabled {
            logger.info(
                "Syncing Launch at Login: preference=\(prefEnabled), actual=\(actualEnabled)")
            setEnabled(prefEnabled)
        }

        cleanupLegacyLaunchAgent()
    }

    /// Get human-readable status for UI
    public var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires Approval"
        case .notFound:
            return "Not Found"
        case .notRegistered:
            return "Disabled"
        @unknown default:
            return "Unknown"
        }
    }
}
