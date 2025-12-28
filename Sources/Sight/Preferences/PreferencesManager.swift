import AppKit
import Combine
import Foundation
import os.log

/// Manages user preferences with UserDefaults persistence
/// Provides JSON schema output for external tools
public final class PreferencesManager: ObservableObject {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let workInterval = "workIntervalSeconds"
        static let preBreak = "preBreakSeconds"
        static let breakDuration = "breakDurationSeconds"
        static let launchAtLogin = "launchAtLogin"
        static let soundEnabled = "soundEnabled"
        static let idlePauseMinutes = "idlePauseMinutes"
        static let idleResetMinutes = "idleResetMinutes"

        // Wellness Reminders
        static let blinkReminderEnabled = "blinkReminderEnabled"
        static let blinkReminderInterval = "blinkReminderIntervalSeconds"
        static let blinkSoundEnabled = "blinkSoundEnabled"
        static let postureReminderEnabled = "postureReminderEnabled"
        static let postureReminderInterval = "postureReminderIntervalSeconds"
        static let postureSoundEnabled = "postureSoundEnabled"

        // Appearance
        static let appearanceMode = "appearanceMode"
        static let accentColor = "accentColor"
        static let overlayOpacity = "overlayOpacity"
        static let blurBackground = "blurBackground"
        static let particleEffects = "particleEffects"

        // Menu Bar
        static let showInMenuBar = "showInMenuBar"
        static let showTimerInMenuBar = "showTimerInMenuBar"

        // Automation / Working Hours
        static let quietHoursEnabled = "quietHoursEnabled"
        static let quietHoursStart = "quietHoursStart"
        static let quietHoursEnd = "quietHoursEnd"
        static let weekendModeEnabled = "weekendModeEnabled"
        static let activeDays = "activeDays"

        // Break Behavior
        static let allowSkipBreak = "allowSkipBreak"
        static let allowPostponeBreak = "allowPostponeBreak"

        // Sounds
        static let breakStartSoundEnabled = "breakStartSoundEnabled"
        static let breakEndSoundEnabled = "breakEndSoundEnabled"
        static let soundVolume = "soundVolume"

        // Profiles
        static let activeProfile = "activeProfile"

        // Meeting Detection
        static let meetingDetectionEnabled = "meetingDetectionEnabled"

        // Long Break
        static let longBreakDurationSeconds = "longBreakDurationSeconds"
    }

    // MARK: - Published Properties

    @Published public var workIntervalSeconds: Int {
        didSet {
            let clamped = min(max(workIntervalSeconds, 60), 7200)  // 1-120 minutes
            if clamped != workIntervalSeconds { workIntervalSeconds = clamped }
            defaults.set(workIntervalSeconds, forKey: Keys.workInterval)
        }
    }

    @Published public var preBreakSeconds: Int {
        didSet {
            // Allow 0 (disabled) or 1-60 seconds
            let clamped = min(max(preBreakSeconds, 0), 60)
            if clamped != preBreakSeconds { preBreakSeconds = clamped }
            defaults.set(preBreakSeconds, forKey: Keys.preBreak)
        }
    }

    @Published public var breakDurationSeconds: Int {
        didSet {
            let clamped = min(max(breakDurationSeconds, 5), 600)  // 5 seconds - 10 minutes
            if clamped != breakDurationSeconds { breakDurationSeconds = clamped }
            defaults.set(breakDurationSeconds, forKey: Keys.breakDuration)
        }
    }

    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LoginItemManager.shared.setEnabled(launchAtLogin)
        }
    }

    @Published public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    @Published public var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    @Published public var idlePauseMinutes: Int {
        didSet { defaults.set(idlePauseMinutes, forKey: Keys.idlePauseMinutes) }
    }

    @Published public var idleResetMinutes: Int {
        didSet { defaults.set(idleResetMinutes, forKey: Keys.idleResetMinutes) }
    }

    // MARK: - Profile Properties

    @Published public var activeProfile: BreakProfile {
        didSet {
            defaults.set(activeProfile.rawValue, forKey: Keys.activeProfile)
        }
    }

    @Published public var meetingDetectionEnabled: Bool {
        didSet { defaults.set(meetingDetectionEnabled, forKey: Keys.meetingDetectionEnabled) }
    }

    /// Apply a break profile's settings
    public func applyProfile(_ profile: BreakProfile) {
        guard profile != .custom else {
            activeProfile = profile
            return
        }

        // Apply profile settings
        workIntervalSeconds = profile.workInterval
        breakDurationSeconds = profile.breakDuration
        preBreakSeconds = profile.preBreakWarning
        activeProfile = profile
    }

    // MARK: - Wellness Reminders Properties

    @Published public var blinkReminderEnabled: Bool {
        didSet { defaults.set(blinkReminderEnabled, forKey: Keys.blinkReminderEnabled) }
    }

    @Published public var blinkReminderIntervalSeconds: Int {
        didSet { defaults.set(blinkReminderIntervalSeconds, forKey: Keys.blinkReminderInterval) }
    }

    @Published public var blinkSoundEnabled: Bool {
        didSet { defaults.set(blinkSoundEnabled, forKey: Keys.blinkSoundEnabled) }
    }

    @Published public var postureReminderEnabled: Bool {
        didSet { defaults.set(postureReminderEnabled, forKey: Keys.postureReminderEnabled) }
    }

    @Published public var postureReminderIntervalSeconds: Int {
        didSet {
            defaults.set(postureReminderIntervalSeconds, forKey: Keys.postureReminderInterval)
        }
    }

    @Published public var postureSoundEnabled: Bool {
        didSet { defaults.set(postureSoundEnabled, forKey: Keys.postureSoundEnabled) }
    }

    // MARK: - Appearance Properties

    @Published public var appearanceMode: String {
        didSet {
            defaults.set(appearanceMode, forKey: Keys.appearanceMode)
            applyAppearanceMode()
        }
    }

    /// Apply the current appearance mode to the app
    public func applyAppearanceMode() {
        DispatchQueue.main.async {
            switch self.appearanceMode {
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            default:  // "system"
                NSApp.appearance = nil  // Use system default
            }
        }
    }

    @Published public var accentColor: String {
        didSet { defaults.set(accentColor, forKey: Keys.accentColor) }
    }

    @Published public var overlayOpacity: Double {
        didSet { defaults.set(overlayOpacity, forKey: Keys.overlayOpacity) }
    }

    @Published public var blurBackground: Bool {
        didSet { defaults.set(blurBackground, forKey: Keys.blurBackground) }
    }

    @Published public var particleEffects: Bool {
        didSet { defaults.set(particleEffects, forKey: Keys.particleEffects) }
    }

    // MARK: - Menu Bar Properties

    @Published public var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: Keys.showInMenuBar) }
    }

    @Published public var showTimerInMenuBar: Bool {
        didSet { defaults.set(showTimerInMenuBar, forKey: Keys.showTimerInMenuBar) }
    }

    // MARK: - Break Behavior Properties

    @Published public var allowSkipBreak: Bool {
        didSet { defaults.set(allowSkipBreak, forKey: Keys.allowSkipBreak) }
    }

    @Published public var allowPostponeBreak: Bool {
        didSet { defaults.set(allowPostponeBreak, forKey: Keys.allowPostponeBreak) }
    }

    // MARK: - Sound Properties

    @Published public var soundVolume: Double {
        didSet { defaults.set(soundVolume, forKey: Keys.soundVolume) }
    }

    // MARK: - Active Days

    @Published public var activeDays: [Bool] {
        didSet { defaults.set(activeDays, forKey: Keys.activeDays) }
    }

    // MARK: - Automation Properties

    @Published public var quietHoursEnabled: Bool {
        didSet { defaults.set(quietHoursEnabled, forKey: Keys.quietHoursEnabled) }
    }

    @Published public var quietHoursStart: Int {
        didSet { defaults.set(quietHoursStart, forKey: Keys.quietHoursStart) }
    }

    @Published public var quietHoursEnd: Int {
        didSet { defaults.set(quietHoursEnd, forKey: Keys.quietHoursEnd) }
    }

    @Published public var weekendModeEnabled: Bool {
        didSet { defaults.set(weekendModeEnabled, forKey: Keys.weekendModeEnabled) }
    }

    @Published public var pauseForFullscreenApps: Bool {
        didSet { defaults.set(pauseForFullscreenApps, forKey: "pauseForFullscreenApps") }
    }

    @Published public var breakStartSoundEnabled: Bool {
        didSet { defaults.set(breakStartSoundEnabled, forKey: Keys.breakStartSoundEnabled) }
    }

    @Published public var breakEndSoundEnabled: Bool {
        didSet { defaults.set(breakEndSoundEnabled, forKey: Keys.breakEndSoundEnabled) }
    }

    @Published public var longBreakDurationSeconds: Int {
        didSet { defaults.set(longBreakDurationSeconds, forKey: Keys.longBreakDurationSeconds) }
    }

    // MARK: - Private Properties

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.sight.app", category: "Preferences")

    // MARK: - Singleton

    public static let shared = PreferencesManager()

    // MARK: - Initialization

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load values with defaults
        // SECURITY: Defensive clamping on load to handle corrupted UserDefaults
        let rawWorkInterval = defaults.object(forKey: Keys.workInterval) as? Int ?? 20 * 60
        self.workIntervalSeconds = min(max(rawWorkInterval, 60), 7200)

        let rawPreBreak = defaults.object(forKey: Keys.preBreak) as? Int ?? 10
        self.preBreakSeconds = min(max(rawPreBreak, 1), 60)

        let rawBreakDuration = defaults.object(forKey: Keys.breakDuration) as? Int ?? 20
        self.breakDurationSeconds = min(max(rawBreakDuration, 5), 600)

        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true

        let rawIdlePause = defaults.object(forKey: Keys.idlePauseMinutes) as? Int ?? 1
        self.idlePauseMinutes = min(max(rawIdlePause, 1), 60)

        let rawIdleReset = defaults.object(forKey: Keys.idleResetMinutes) as? Int ?? 5
        self.idleResetMinutes = min(max(rawIdleReset, 1), 120)

        // Wellness Reminders defaults
        self.blinkReminderEnabled =
            defaults.object(forKey: Keys.blinkReminderEnabled) as? Bool ?? true
        self.blinkReminderIntervalSeconds =
            defaults.object(forKey: Keys.blinkReminderInterval) as? Int ?? 20
        self.blinkSoundEnabled = defaults.object(forKey: Keys.blinkSoundEnabled) as? Bool ?? false
        self.postureReminderEnabled =
            defaults.object(forKey: Keys.postureReminderEnabled) as? Bool ?? true
        self.postureReminderIntervalSeconds =
            defaults.object(forKey: Keys.postureReminderInterval) as? Int ?? 25 * 60
        self.postureSoundEnabled =
            defaults.object(forKey: Keys.postureSoundEnabled) as? Bool ?? true

        // Appearance defaults
        self.appearanceMode = defaults.string(forKey: Keys.appearanceMode) ?? "system"
        self.accentColor = defaults.string(forKey: Keys.accentColor) ?? "blue"
        self.overlayOpacity = defaults.object(forKey: Keys.overlayOpacity) as? Double ?? 0.9
        self.blurBackground = defaults.object(forKey: Keys.blurBackground) as? Bool ?? true
        self.particleEffects = defaults.object(forKey: Keys.particleEffects) as? Bool ?? true

        // Menu Bar defaults
        self.showInMenuBar = defaults.object(forKey: Keys.showInMenuBar) as? Bool ?? true
        self.showTimerInMenuBar = defaults.object(forKey: Keys.showTimerInMenuBar) as? Bool ?? true

        // Break Behavior defaults
        self.allowSkipBreak = defaults.object(forKey: Keys.allowSkipBreak) as? Bool ?? true
        self.allowPostponeBreak = defaults.object(forKey: Keys.allowPostponeBreak) as? Bool ?? true

        // Sound defaults
        self.soundVolume = defaults.object(forKey: Keys.soundVolume) as? Double ?? 0.7

        // Active Days (Mon-Fri active by default)
        // SECURITY: Validate array length is exactly 7, otherwise use defaults
        let defaultActiveDays = [true, true, true, true, true, false, false]
        if let savedDays = defaults.object(forKey: Keys.activeDays) as? [Bool], savedDays.count == 7
        {
            self.activeDays = savedDays
        } else {
            self.activeDays = defaultActiveDays
        }

        // Profile defaults
        if let profileString = defaults.string(forKey: Keys.activeProfile),
            let profile = BreakProfile(rawValue: profileString)
        {
            self.activeProfile = profile
        } else {
            self.activeProfile = .custom
        }
        self.meetingDetectionEnabled =
            defaults.object(forKey: Keys.meetingDetectionEnabled) as? Bool ?? true

        // Automation defaults
        self.quietHoursEnabled = defaults.bool(forKey: Keys.quietHoursEnabled)
        self.quietHoursStart = defaults.object(forKey: Keys.quietHoursStart) as? Int ?? 22
        self.quietHoursEnd = defaults.object(forKey: Keys.quietHoursEnd) as? Int ?? 8
        self.weekendModeEnabled = defaults.bool(forKey: Keys.weekendModeEnabled)
        self.pauseForFullscreenApps =
            defaults.object(forKey: "pauseForFullscreenApps") as? Bool ?? false

        self.breakStartSoundEnabled =
            defaults.object(forKey: Keys.breakStartSoundEnabled) as? Bool ?? true
        self.breakEndSoundEnabled =
            defaults.object(forKey: Keys.breakEndSoundEnabled) as? Bool ?? true

        self.longBreakDurationSeconds =
            defaults.object(forKey: Keys.longBreakDurationSeconds) as? Int ?? 5 * 60  // 5 minutes default

        logger.info("Preferences loaded")

        // Apply appearance on startup
        applyAppearanceMode()
    }

    // MARK: - Configuration Bridge

    /// Convert preferences to TimerConfiguration
    public var timerConfiguration: TimerConfiguration {
        TimerConfiguration(
            workIntervalSeconds: workIntervalSeconds,
            preBreakSeconds: preBreakSeconds,
            breakDurationSeconds: breakDurationSeconds
        )
    }

    // MARK: - JSON Schema

    /// Returns current preferences as JSON
    public func schemaJSON() -> String {
        let schema: [String: Any] = [
            "version": 1,
            "preferences": [
                "workIntervalSeconds": workIntervalSeconds,
                "preBreakSeconds": preBreakSeconds,
                "breakDurationSeconds": breakDurationSeconds,
                "launchAtLogin": launchAtLogin,
                "soundEnabled": soundEnabled,
            ],
            "metadata": [
                "lastModified": ISO8601DateFormatter().string(from: Date()),
                "platform": "macOS",
            ],
        ]

        guard
            let data = try? JSONSerialization.data(withJSONObject: schema, options: .prettyPrinted),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{\"error\": \"Failed to serialize preferences\"}"
        }

        return json
    }

    // MARK: - Reset

    /// Reset all preferences to defaults
    public func resetToDefaults() {
        workIntervalSeconds = 20 * 60
        preBreakSeconds = 10
        breakDurationSeconds = 20
        launchAtLogin = false
        soundEnabled = true

        // Wellness Reminders defaults
        blinkReminderEnabled = true
        blinkReminderIntervalSeconds = 20
        blinkSoundEnabled = false
        postureReminderEnabled = true
        postureReminderIntervalSeconds = 25 * 60
        postureSoundEnabled = true

        // Appearance defaults
        appearanceMode = "system"
        accentColor = "blue"
        overlayOpacity = 0.9

        // Automation defaults
        quietHoursEnabled = false
        quietHoursStart = 22
        quietHoursEnd = 8
        weekendModeEnabled = false

        breakStartSoundEnabled = true
        breakEndSoundEnabled = true

        logger.info("Preferences reset to defaults")
    }

}
