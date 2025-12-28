import Foundation
import ServiceManagement
import os.log

/// Manages Launch at Login functionality using SMAppService (macOS 13+)
public final class LoginItemManager {
    
    public static let shared = LoginItemManager()
    
    private let logger = Logger(subsystem: "com.sight.app", category: "LoginItem")
    
    /// Check if running from Applications folder (required for launch at login)
    private var isRunningFromProperLocation: Bool {
        guard let bundlePath = Bundle.main.bundlePath as NSString? else { return false }
        // Must be in /Applications or ~/Applications to use SMAppService
        return bundlePath.hasPrefix("/Applications/") || 
               bundlePath.contains("/Applications/") ||
               Bundle.main.bundleIdentifier != nil
    }
    
    /// Check if this is a dev/debug build
    private var isDevBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.bundleIdentifier == nil
        #endif
    }
    
    /// Whether launch at login is currently enabled
    public var isEnabled: Bool {
        get {
            // In dev mode, just return the preference value
            if isDevBuild { return UserDefaults.standard.bool(forKey: "launchAtLogin") }
            
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return UserDefaults.standard.bool(forKey: "launchAtLogin")
            }
        }
        set {
            setEnabled(newValue)
        }
    }
    
    /// Enable or disable launch at login
    public func setEnabled(_ enabled: Bool) {
        // In dev mode, just store the preference without touching SMAppService
        if isDevBuild {
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
            logger.debug("Launch at Login preference saved (dev mode - SMAppService skipped)")
            return
        }
        
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    logger.info("Launch at Login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    logger.info("Launch at Login disabled")
                }
            } catch {
                // Only log at warning level - this is expected when not properly signed
                logger.warning("Launch at Login unavailable: \(error.localizedDescription)")
                // Still save the preference for when app is properly installed
                UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
            }
        } else {
            // Fallback for older macOS - just store preference
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        }
    }
    
    /// Check and sync the launch at login state with preferences
    public func syncWithPreferences(_ preferences: PreferencesManager) {
        // In dev mode, just use stored preference
        if isDevBuild { return }
        
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            // Only sync if we can actually read the status
            if status != .notRegistered {
                let systemEnabled = status == .enabled
                if systemEnabled != preferences.launchAtLogin {
                    preferences.launchAtLogin = systemEnabled
                }
            }
        }
    }
}
