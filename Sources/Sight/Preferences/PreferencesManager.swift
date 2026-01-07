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
        static let flashDuration = "flashDurationMs"
        static let flashColor = "flashColor"
        static let postureReminderEnabled = "postureReminderEnabled"
        static let postureReminderInterval = "postureReminderIntervalSeconds"
        static let postureSoundEnabled = "postureSoundEnabled"
        static let dimScreenOnReminder = "dimScreenOnReminder"
        static let showRemindersDuringPauses = "showRemindersDuringPauses"
        static let resetTimersAfterBreak = "resetTimersAfterBreak"
        static let nudgeDimIntensity = "nudgeDimIntensity"

        // Appearance
        static let appearanceMode = "appearanceMode"
        static let accentColor = "accentColor"
        static let accentHue = "accentHue"
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
        static let maxPostpones = "maxPostpones"
        static let enforcementLevel = "enforcementLevel"
        static let showBreakPreview = "showBreakPreview"

        // Break Skip Difficulty
        static let breakSkipDifficulty = "breakSkipDifficulty"
        static let dontShowWhileTyping = "dontShowWhileTyping"

        // Long Breaks
        static let longBreakEnabled = "longBreakEnabled"
        static let longBreakInterval = "longBreakInterval"

        // Office Hours
        static let officeHoursEnabled = "officeHoursEnabled"
        static let officeHoursStart = "officeHoursStart"
        static let officeHoursEnd = "officeHoursEnd"

        // Countdown Before Break
        static let countdownEnabled = "countdownEnabled"
        static let countdownDuration = "countdownDuration"

        // Overtime Nudge
        static let overtimeNudgeEnabled = "overtimeNudgeEnabled"
        static let overtimeShowWhenPaused = "overtimeShowWhenPaused"

        // More Options
        static let endBreakEarly = "endBreakEarly"
        static let lockMacOnBreak = "lockMacOnBreak"

        // Break Screen Appearance
        static let breakBackgroundType = "breakBackgroundType"
        static let breakCustomImagePath = "breakCustomImagePath"
        static let breakBlurBackground = "breakBlurBackground"
        static let breakCustomMessages = "breakCustomMessages"
        static let breakHideMessages = "breakHideMessages"
        static let breakAlertPosition = "breakAlertPosition"
        static let breakGradientPreset = "breakGradientPreset"

        // Session Behavior
        static let autoStartOnLaunch = "autoStartOnLaunch"
        static let rememberLastState = "rememberLastState"

        // Sounds
        static let breakStartSoundEnabled = "breakStartSoundEnabled"
        static let breakEndSoundEnabled = "breakEndSoundEnabled"
        static let breakStartSoundType = "breakStartSoundType"
        static let breakEndSoundType = "breakEndSoundType"
        static let nudgeSoundType = "nudgeSoundType"
        static let soundVolume = "soundVolume"
        static let soundPair = "soundPair"
        static let wellnessReminderVolume = "wellnessReminderVolume"
        static let breakReminderSoundEnabled = "breakReminderSoundEnabled"
        static let smartPauseSoundEnabled = "smartPauseSoundEnabled"
        static let smartPauseNotificationEnabled = "smartPauseNotificationEnabled"
        static let activeAfterIdleSoundEnabled = "activeAfterIdleSoundEnabled"
        static let overtimeNudgeSoundEnabled = "overtimeNudgeSoundEnabled"

        // Profiles
        static let activeProfile = "activeProfile"

        // Meeting Detection
        static let meetingDetectionEnabled = "meetingDetectionEnabled"

        // Long Break
        static let longBreakDurationSeconds = "longBreakDurationSeconds"

        // Shortcuts
        static let shortcutToggleTimer = "shortcutToggleTimer"
        static let shortcutTakeBreak = "shortcutTakeBreak"
        static let shortcutSkipBreak = "shortcutSkipBreak"
        static let shortcutPreferences = "shortcutPreferences"
        static let shortcutsEnabled = "shortcutsEnabled"
        static let pauseForFullscreenApps = "pauseForFullscreenApps"
    }

    // MARK: - Enforcement Level

    /// Enforcement level for break compliance
    public enum EnforcementLevel: String, CaseIterable, Codable {
        case gentle = "gentle"
        case balanced = "balanced"
        case strict = "strict"
        case zenMaster = "zenMaster"

        public var displayName: String {
            switch self {
            case .gentle: return "Gentle"
            case .balanced: return "Balanced"
            case .strict: return "Strict"
            case .zenMaster: return "Zen Master"
            }
        }

        public var allowSkip: Bool {
            switch self {
            case .gentle, .balanced: return true
            case .strict, .zenMaster: return false
            }
        }

        public var maxPostpones: Int {
            switch self {
            case .gentle: return 99  // Unlimited
            case .balanced: return 2
            case .strict: return 1
            case .zenMaster: return 0
            }
        }

        public var preWarningSeconds: Int {
            switch self {
            case .gentle: return 30
            case .balanced: return 15
            case .strict: return 5
            case .zenMaster: return 0
            }
        }

        public var description: String {
            switch self {
            case .gentle: return "Flexible - Skip and postpone freely"
            case .balanced: return "Moderate - Limited postpones"
            case .strict: return "Focused - No skipping, 1 postpone"
            case .zenMaster: return "Maximum commitment - No escape"
            }
        }
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

    /// Flash duration in milliseconds (400-900)
    @Published public var flashDurationMs: Int {
        didSet { defaults.set(flashDurationMs, forKey: Keys.flashDuration) }
    }

    /// Flash color for blink reminders
    @Published public var flashColor: String {
        didSet { defaults.set(flashColor, forKey: Keys.flashColor) }
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

    /// Dim the screen when showing wellness reminders
    @Published public var dimScreenOnReminder: Bool {
        didSet { defaults.set(dimScreenOnReminder, forKey: Keys.dimScreenOnReminder) }
    }

    /// Show wellness reminders during pauses (meetings, videos, etc.)
    @Published public var showRemindersDuringPauses: Bool {
        didSet { defaults.set(showRemindersDuringPauses, forKey: Keys.showRemindersDuringPauses) }
    }

    /// Reset wellness reminder timers after each break
    @Published public var resetTimersAfterBreak: Bool {
        didSet { defaults.set(resetTimersAfterBreak, forKey: Keys.resetTimersAfterBreak) }
    }

    /// Dim overlay intensity for nudges (0.0-1.0)
    @Published public var nudgeDimIntensity: CGFloat {
        didSet { defaults.set(nudgeDimIntensity, forKey: Keys.nudgeDimIntensity) }
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

    /// Accent hue value for dynamic theme colors (0.0 - 1.0)
    @Published public var accentHue: Double {
        didSet {
            let clamped = min(max(accentHue, 0.0), 1.0)
            if clamped != accentHue { accentHue = clamped }
            defaults.set(accentHue, forKey: Keys.accentHue)
        }
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

    @Published public var maxPostpones: Int {
        didSet {
            let clamped = min(max(maxPostpones, 0), 99)
            if clamped != maxPostpones { maxPostpones = clamped }
            defaults.set(maxPostpones, forKey: Keys.maxPostpones)
        }
    }

    @Published public var enforcementLevel: EnforcementLevel {
        didSet {
            defaults.set(enforcementLevel.rawValue, forKey: Keys.enforcementLevel)
            // Auto-apply enforcement level settings
            allowSkipBreak = enforcementLevel.allowSkip
            maxPostpones = enforcementLevel.maxPostpones
        }
    }

    @Published public var showBreakPreview: Bool {
        didSet { defaults.set(showBreakPreview, forKey: Keys.showBreakPreview) }
    }

    // MARK: - Break Skip Difficulty

    @Published public var breakSkipDifficulty: String {
        didSet { defaults.set(breakSkipDifficulty, forKey: Keys.breakSkipDifficulty) }
    }

    @Published public var dontShowWhileTyping: Bool {
        didSet { defaults.set(dontShowWhileTyping, forKey: Keys.dontShowWhileTyping) }
    }

    // MARK: - Long Breaks

    @Published public var longBreakEnabled: Bool {
        didSet { defaults.set(longBreakEnabled, forKey: Keys.longBreakEnabled) }
    }

    @Published public var longBreakInterval: Int {
        didSet { defaults.set(longBreakInterval, forKey: Keys.longBreakInterval) }
    }

    // MARK: - Office Hours

    @Published public var officeHoursEnabled: Bool {
        didSet { defaults.set(officeHoursEnabled, forKey: Keys.officeHoursEnabled) }
    }

    @Published public var officeHoursStart: Date {
        didSet { defaults.set(officeHoursStart, forKey: Keys.officeHoursStart) }
    }

    @Published public var officeHoursEnd: Date {
        didSet { defaults.set(officeHoursEnd, forKey: Keys.officeHoursEnd) }
    }

    // MARK: - Countdown Before Break

    @Published public var countdownEnabled: Bool {
        didSet { defaults.set(countdownEnabled, forKey: Keys.countdownEnabled) }
    }

    @Published public var countdownDuration: Int {
        didSet { defaults.set(countdownDuration, forKey: Keys.countdownDuration) }
    }

    // MARK: - Overtime Nudge

    @Published public var overtimeNudgeEnabled: Bool {
        didSet { defaults.set(overtimeNudgeEnabled, forKey: Keys.overtimeNudgeEnabled) }
    }

    @Published public var overtimeShowWhenPaused: Bool {
        didSet { defaults.set(overtimeShowWhenPaused, forKey: Keys.overtimeShowWhenPaused) }
    }

    // MARK: - More Break Options

    @Published public var endBreakEarly: Bool {
        didSet { defaults.set(endBreakEarly, forKey: Keys.endBreakEarly) }
    }

    @Published public var lockMacOnBreak: Bool {
        didSet { defaults.set(lockMacOnBreak, forKey: Keys.lockMacOnBreak) }
    }

    // MARK: - Break Screen Appearance Properties

    /// Background type: "gradient", "wallpaper", or "custom"
    @Published public var breakBackgroundType: String {
        didSet { defaults.set(breakBackgroundType, forKey: Keys.breakBackgroundType) }
    }

    /// Path to custom background image
    @Published public var breakCustomImagePath: String {
        didSet { defaults.set(breakCustomImagePath, forKey: Keys.breakCustomImagePath) }
    }

    /// Whether to blur the background
    @Published public var breakBlurBackground: Bool {
        didSet { defaults.set(breakBlurBackground, forKey: Keys.breakBlurBackground) }
    }

    /// Custom messages to display during break
    @Published public var breakCustomMessages: [String] {
        didSet { defaults.set(breakCustomMessages, forKey: Keys.breakCustomMessages) }
    }

    /// Whether to hide all break screen messages
    @Published public var breakHideMessages: Bool {
        didSet { defaults.set(breakHideMessages, forKey: Keys.breakHideMessages) }
    }

    /// Alert position: "topLeft", "topCenter", "topRight", "bottomLeft", "bottomCenter", "bottomRight"
    @Published public var breakAlertPosition: String {
        didSet { defaults.set(breakAlertPosition, forKey: Keys.breakAlertPosition) }
    }

    /// Gradient preset: "sunset", "ocean", "forest", "night", "aurora"
    @Published public var breakGradientPreset: String {
        didSet { defaults.set(breakGradientPreset, forKey: Keys.breakGradientPreset) }
    }

    // MARK: - Session Behavior Properties

    @Published public var autoStartOnLaunch: Bool {
        didSet { defaults.set(autoStartOnLaunch, forKey: Keys.autoStartOnLaunch) }
    }

    @Published public var rememberLastState: Bool {
        didSet { defaults.set(rememberLastState, forKey: Keys.rememberLastState) }
    }

    // MARK: - Sound Properties

    @Published public var soundVolume: Double {
        didSet { defaults.set(soundVolume, forKey: Keys.soundVolume) }
    }

    @Published public var breakStartSoundType: String {
        didSet { defaults.set(breakStartSoundType, forKey: Keys.breakStartSoundType) }
    }

    @Published public var breakEndSoundType: String {
        didSet { defaults.set(breakEndSoundType, forKey: Keys.breakEndSoundType) }
    }

    @Published public var nudgeSoundType: String {
        didSet { defaults.set(nudgeSoundType, forKey: Keys.nudgeSoundType) }
    }

    // MARK: - Shortcut Properties

    @Published public var shortcutsEnabled: Bool {
        didSet { defaults.set(shortcutsEnabled, forKey: Keys.shortcutsEnabled) }
    }

    @Published public var shortcutToggleTimer: String {
        didSet { defaults.set(shortcutToggleTimer, forKey: Keys.shortcutToggleTimer) }
    }

    @Published public var shortcutTakeBreak: String {
        didSet { defaults.set(shortcutTakeBreak, forKey: Keys.shortcutTakeBreak) }
    }

    @Published public var shortcutSkipBreak: String {
        didSet { defaults.set(shortcutSkipBreak, forKey: Keys.shortcutSkipBreak) }
    }

    @Published public var shortcutPreferences: String {
        didSet { defaults.set(shortcutPreferences, forKey: Keys.shortcutPreferences) }
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
        didSet { defaults.set(pauseForFullscreenApps, forKey: Keys.pauseForFullscreenApps) }
    }

    @Published public var breakStartSoundEnabled: Bool {
        didSet { defaults.set(breakStartSoundEnabled, forKey: Keys.breakStartSoundEnabled) }
    }

    @Published public var breakEndSoundEnabled: Bool {
        didSet { defaults.set(breakEndSoundEnabled, forKey: Keys.breakEndSoundEnabled) }
    }

    /// Sound pair selection (Default, Chime, Bell, etc.)
    @Published public var soundPair: String {
        didSet { defaults.set(soundPair, forKey: Keys.soundPair) }
    }

    /// Wellness reminder sounds volume (0.0-1.0)
    @Published public var wellnessReminderVolume: Double {
        didSet { defaults.set(wellnessReminderVolume, forKey: Keys.wellnessReminderVolume) }
    }

    /// Play sound when break reminder appears
    @Published public var breakReminderSoundEnabled: Bool {
        didSet { defaults.set(breakReminderSoundEnabled, forKey: Keys.breakReminderSoundEnabled) }
    }

    /// Play sound for smart pause notifications
    @Published public var smartPauseSoundEnabled: Bool {
        didSet { defaults.set(smartPauseSoundEnabled, forKey: Keys.smartPauseSoundEnabled) }
    }

    /// Show notification for smart pause start/end
    @Published public var smartPauseNotificationEnabled: Bool {
        didSet {
            defaults.set(smartPauseNotificationEnabled, forKey: Keys.smartPauseNotificationEnabled)
        }
    }

    /// Play sound when user becomes active after idle
    @Published public var activeAfterIdleSoundEnabled: Bool {
        didSet {
            defaults.set(activeAfterIdleSoundEnabled, forKey: Keys.activeAfterIdleSoundEnabled)
        }
    }

    /// Play sound for overtime nudge
    @Published public var overtimeNudgeSoundEnabled: Bool {
        didSet { defaults.set(overtimeNudgeSoundEnabled, forKey: Keys.overtimeNudgeSoundEnabled) }
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
            defaults.object(forKey: Keys.blinkReminderInterval) as? Int ?? 120  // 2 minutes default
        self.blinkSoundEnabled = defaults.object(forKey: Keys.blinkSoundEnabled) as? Bool ?? false
        self.flashDurationMs = defaults.object(forKey: Keys.flashDuration) as? Int ?? 700
        self.flashColor = defaults.string(forKey: Keys.flashColor) ?? "cyan"
        self.postureReminderEnabled =
            defaults.object(forKey: Keys.postureReminderEnabled) as? Bool ?? true
        self.postureReminderIntervalSeconds =
            defaults.object(forKey: Keys.postureReminderInterval) as? Int ?? 25 * 60
        self.postureSoundEnabled =
            defaults.object(forKey: Keys.postureSoundEnabled) as? Bool ?? true

        // Common wellness settings
        self.dimScreenOnReminder =
            defaults.object(forKey: Keys.dimScreenOnReminder) as? Bool ?? true
        self.showRemindersDuringPauses =
            defaults.object(forKey: Keys.showRemindersDuringPauses) as? Bool ?? false
        self.resetTimersAfterBreak =
            defaults.object(forKey: Keys.resetTimersAfterBreak) as? Bool ?? true
        self.nudgeDimIntensity =
            defaults.object(forKey: Keys.nudgeDimIntensity) as? CGFloat ?? 0.5

        // Appearance defaults
        self.appearanceMode = defaults.string(forKey: Keys.appearanceMode) ?? "system"
        self.accentColor = defaults.string(forKey: Keys.accentColor) ?? "cyan"
        self.accentHue = defaults.object(forKey: Keys.accentHue) as? Double ?? 0.52  // Cyan default
        self.overlayOpacity = defaults.object(forKey: Keys.overlayOpacity) as? Double ?? 0.9
        self.blurBackground = defaults.object(forKey: Keys.blurBackground) as? Bool ?? true
        self.particleEffects = defaults.object(forKey: Keys.particleEffects) as? Bool ?? true

        // Menu Bar defaults
        self.showInMenuBar = defaults.object(forKey: Keys.showInMenuBar) as? Bool ?? true
        self.showTimerInMenuBar = defaults.object(forKey: Keys.showTimerInMenuBar) as? Bool ?? true

        // Break Behavior defaults
        self.allowSkipBreak = defaults.object(forKey: Keys.allowSkipBreak) as? Bool ?? true
        self.allowPostponeBreak = defaults.object(forKey: Keys.allowPostponeBreak) as? Bool ?? true
        self.maxPostpones = defaults.object(forKey: Keys.maxPostpones) as? Int ?? 3
        self.showBreakPreview = defaults.object(forKey: Keys.showBreakPreview) as? Bool ?? true

        // Enforcement Level
        if let levelString = defaults.string(forKey: Keys.enforcementLevel),
            let level = EnforcementLevel(rawValue: levelString)
        {
            self.enforcementLevel = level
        } else {
            self.enforcementLevel = .gentle
        }

        // Session Behavior defaults
        self.autoStartOnLaunch = defaults.object(forKey: Keys.autoStartOnLaunch) as? Bool ?? false
        self.rememberLastState = defaults.object(forKey: Keys.rememberLastState) as? Bool ?? true

        // Sound defaults
        self.soundVolume = defaults.object(forKey: Keys.soundVolume) as? Double ?? 0.7
        self.breakStartSoundType = defaults.string(forKey: Keys.breakStartSoundType) ?? "Chime"
        self.breakEndSoundType = defaults.string(forKey: Keys.breakEndSoundType) ?? "Bell"
        self.nudgeSoundType = defaults.string(forKey: Keys.nudgeSoundType) ?? "Gentle"

        // Shortcut defaults (format: "modifiers:keyCode" e.g. "cmd+ctrl:35" for ⌘⌃P)
        self.shortcutsEnabled = defaults.object(forKey: Keys.shortcutsEnabled) as? Bool ?? true
        self.shortcutToggleTimer =
            defaults.string(forKey: Keys.shortcutToggleTimer) ?? "cmd+ctrl:35"  // P
        self.shortcutTakeBreak = defaults.string(forKey: Keys.shortcutTakeBreak) ?? "cmd+ctrl:11"  // B
        self.shortcutSkipBreak = defaults.string(forKey: Keys.shortcutSkipBreak) ?? "cmd+ctrl:1"  // S
        self.shortcutPreferences =
            defaults.string(forKey: Keys.shortcutPreferences) ?? "cmd+ctrl:43"  // ,

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
            defaults.object(forKey: Keys.pauseForFullscreenApps) as? Bool ?? false

        self.breakStartSoundEnabled =
            defaults.object(forKey: Keys.breakStartSoundEnabled) as? Bool ?? true
        self.breakEndSoundEnabled =
            defaults.object(forKey: Keys.breakEndSoundEnabled) as? Bool ?? true

        // Additional sound settings
        self.soundPair = defaults.string(forKey: Keys.soundPair) ?? "Default"
        self.wellnessReminderVolume =
            defaults.object(forKey: Keys.wellnessReminderVolume) as? Double ?? 0.7
        self.breakReminderSoundEnabled =
            defaults.object(forKey: Keys.breakReminderSoundEnabled) as? Bool ?? true
        self.smartPauseSoundEnabled =
            defaults.object(forKey: Keys.smartPauseSoundEnabled) as? Bool ?? true
        self.smartPauseNotificationEnabled =
            defaults.object(forKey: Keys.smartPauseNotificationEnabled) as? Bool ?? true
        self.activeAfterIdleSoundEnabled =
            defaults.object(forKey: Keys.activeAfterIdleSoundEnabled) as? Bool ?? false
        self.overtimeNudgeSoundEnabled =
            defaults.object(forKey: Keys.overtimeNudgeSoundEnabled) as? Bool ?? true

        self.longBreakDurationSeconds =
            defaults.object(forKey: Keys.longBreakDurationSeconds) as? Int ?? 5 * 60  // 5 minutes default

        // Break Skip Difficulty defaults
        self.breakSkipDifficulty = defaults.string(forKey: Keys.breakSkipDifficulty) ?? "balanced"
        self.dontShowWhileTyping =
            defaults.object(forKey: Keys.dontShowWhileTyping) as? Bool ?? false

        // Long Breaks defaults
        self.longBreakEnabled = defaults.object(forKey: Keys.longBreakEnabled) as? Bool ?? true
        self.longBreakInterval = defaults.object(forKey: Keys.longBreakInterval) as? Int ?? 4

        // Office Hours defaults
        self.officeHoursEnabled = defaults.object(forKey: Keys.officeHoursEnabled) as? Bool ?? false
        let defaultStart = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        let defaultEnd = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
        self.officeHoursStart =
            defaults.object(forKey: Keys.officeHoursStart) as? Date ?? defaultStart
        self.officeHoursEnd = defaults.object(forKey: Keys.officeHoursEnd) as? Date ?? defaultEnd

        // Countdown Before Break defaults
        self.countdownEnabled = defaults.object(forKey: Keys.countdownEnabled) as? Bool ?? true
        self.countdownDuration = defaults.object(forKey: Keys.countdownDuration) as? Int ?? 5

        // Overtime Nudge defaults
        self.overtimeNudgeEnabled =
            defaults.object(forKey: Keys.overtimeNudgeEnabled) as? Bool ?? false
        self.overtimeShowWhenPaused =
            defaults.object(forKey: Keys.overtimeShowWhenPaused) as? Bool ?? false

        // More Options defaults
        self.endBreakEarly = defaults.object(forKey: Keys.endBreakEarly) as? Bool ?? false
        self.lockMacOnBreak = defaults.object(forKey: Keys.lockMacOnBreak) as? Bool ?? false

        // Break Screen Appearance defaults
        self.breakBackgroundType = defaults.string(forKey: Keys.breakBackgroundType) ?? "wallpaper"
        self.breakCustomImagePath = defaults.string(forKey: Keys.breakCustomImagePath) ?? ""
        self.breakBlurBackground =
            defaults.object(forKey: Keys.breakBlurBackground) as? Bool ?? true
        self.breakCustomMessages = defaults.stringArray(forKey: Keys.breakCustomMessages) ?? []
        self.breakHideMessages = defaults.object(forKey: Keys.breakHideMessages) as? Bool ?? false
        self.breakAlertPosition = defaults.string(forKey: Keys.breakAlertPosition) ?? "topCenter"
        self.breakGradientPreset = defaults.string(forKey: Keys.breakGradientPreset) ?? "sunset"

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
        // Timer intervals
        workIntervalSeconds = 20 * 60
        preBreakSeconds = 10
        breakDurationSeconds = 20

        // Startup
        launchAtLogin = false
        soundEnabled = true
        autoStartOnLaunch = false
        rememberLastState = true

        // Idle behavior
        idlePauseMinutes = 1
        idleResetMinutes = 5

        // Wellness Reminders
        blinkReminderEnabled = true
        blinkReminderIntervalSeconds = 120
        blinkSoundEnabled = false
        flashDurationMs = 700
        flashColor = "cyan"
        postureReminderEnabled = true
        postureReminderIntervalSeconds = 25 * 60
        postureSoundEnabled = true
        dimScreenOnReminder = true
        showRemindersDuringPauses = false
        resetTimersAfterBreak = true
        nudgeDimIntensity = 0.5

        // Appearance
        appearanceMode = "system"
        accentColor = "cyan"
        accentHue = 0.52
        overlayOpacity = 0.9
        blurBackground = true
        particleEffects = true

        // Menu Bar
        showInMenuBar = true
        showTimerInMenuBar = true

        // Break Behavior
        allowSkipBreak = true
        allowPostponeBreak = true
        maxPostpones = 3
        enforcementLevel = .gentle
        showBreakPreview = true
        breakSkipDifficulty = "balanced"
        dontShowWhileTyping = false

        // Long Breaks
        longBreakEnabled = true
        longBreakInterval = 4
        longBreakDurationSeconds = 5 * 60

        // Office Hours
        officeHoursEnabled = false
        let calendar = Calendar.current
        officeHoursStart = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        officeHoursEnd = calendar.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

        // Countdown
        countdownEnabled = true
        countdownDuration = 5

        // Overtime Nudge
        overtimeNudgeEnabled = false
        overtimeShowWhenPaused = false

        // More Options
        endBreakEarly = false
        lockMacOnBreak = false

        // Break Screen Appearance
        breakBackgroundType = "wallpaper"
        breakCustomImagePath = ""
        breakBlurBackground = true
        breakCustomMessages = []
        breakHideMessages = false
        breakAlertPosition = "topCenter"
        breakGradientPreset = "sunset"

        // Sounds
        soundVolume = 0.7
        breakStartSoundEnabled = true
        breakEndSoundEnabled = true
        breakStartSoundType = "Chime"
        breakEndSoundType = "Bell"
        nudgeSoundType = "Gentle"
        soundPair = "Default"
        wellnessReminderVolume = 0.7
        breakReminderSoundEnabled = true
        smartPauseSoundEnabled = true
        smartPauseNotificationEnabled = true
        activeAfterIdleSoundEnabled = false
        overtimeNudgeSoundEnabled = true

        // Automation
        quietHoursEnabled = false
        quietHoursStart = 22
        quietHoursEnd = 8
        weekendModeEnabled = false
        pauseForFullscreenApps = false
        activeDays = [true, true, true, true, true, false, false]

        // Shortcuts
        shortcutsEnabled = true
        shortcutToggleTimer = "cmd+ctrl:35"
        shortcutTakeBreak = "cmd+ctrl:11"
        shortcutSkipBreak = "cmd+ctrl:1"
        shortcutPreferences = "cmd+ctrl:43"

        // Profile
        activeProfile = .custom
        meetingDetectionEnabled = true

        logger.info("Preferences reset to defaults")
    }

}
