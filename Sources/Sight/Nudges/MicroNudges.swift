import Combine
import Foundation
import UserNotifications
import os.log

// MARK: - Nudge Types

/// Types of micro-nudges
public enum NudgeType: String, CaseIterable, Codable {
    case blink  // Every 20 seconds
    case posture  // Every 20-30 minutes
    case miniExercise  // Every 45-60 minutes

    public var defaultInterval: TimeInterval {
        switch self {
        case .blink: return 20  // seconds
        case .posture: return 25 * 60  // 25 minutes
        case .miniExercise: return 50 * 60  // 50 minutes
        }
    }

    public var displayName: String {
        switch self {
        case .blink: return "Blink Reminder"
        case .posture: return "Posture Check"
        case .miniExercise: return "Mini Exercise"
        }
    }
}

// MARK: - Nudge Style

/// Visual prominence of nudge
public enum NudgeStyle: String, Codable {
    case subtle  // Small, translucent, auto-dismiss
    case normal  // Standard size, requires attention
    case prominent  // Larger, modal-like
}

// MARK: - Mini Exercise

/// A micro-exercise suggestion
public struct MiniExercise: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let durationSeconds: Int
    public let instruction: String
    public let icon: String

    public init(
        name: String, durationSeconds: Int, instruction: String, icon: String = "figure.cooldown"
    ) {
        self.id = UUID()
        self.name = name
        self.durationSeconds = durationSeconds
        self.instruction = instruction
        self.icon = icon
    }

    /// Default exercises
    public static let defaults: [MiniExercise] = [
        MiniExercise(
            name: "Neck Rolls", durationSeconds: 30,
            instruction: "Slowly roll your head in circles", icon: "figure.cooldown"),
        MiniExercise(
            name: "Shoulder Shrugs", durationSeconds: 20,
            instruction: "Raise shoulders to ears, hold, release", icon: "figure.arms.open"),
        MiniExercise(
            name: "Wrist Circles", durationSeconds: 20,
            instruction: "Rotate wrists in both directions", icon: "hand.wave"),
        MiniExercise(
            name: "Eye Palming", durationSeconds: 30,
            instruction: "Cover eyes with warm palms, relax", icon: "eye.slash"),
        MiniExercise(
            name: "Desk Stretch", durationSeconds: 45,
            instruction: "Stand, reach for the ceiling, hold", icon: "figure.stand"),
        MiniExercise(
            name: "Deep Breaths", durationSeconds: 30,
            instruction: "Inhale 4 counts, hold 4, exhale 4", icon: "lungs"),
    ]
}

// MARK: - UX Copy

/// Localized UX copy for nudge prompts
public struct NudgeCopy {

    // MARK: - Blink Messages

    public static let blinkMessages = [
        "Blink 👀",
        "Remember to blink",
        "Blink break",
        "Close & open",
    ]

    // MARK: - Posture Messages

    public static let postureMessages = [
        "Sit up straight 🧘",
        "Check your posture",
        "Shoulders back, chin up",
        "Relax your shoulders",
        "Spine check ✓",
        "Are you slouching?",
        "Posture moment",
    ]

    // MARK: - Exercise Prompts

    public static let exercisePrompts = [
        "Time for a quick stretch",
        "Mini exercise break",
        "Move your body for a moment",
        "Stretch it out",
    ]

    // MARK: - Snooze Messages

    public static let snoozeConfirmation = "Snoozed for %d minutes"
    public static let snoozeWarning = "You've snoozed %d times. Consider taking a break."

    // MARK: - Escalation Messages

    public static let escalationSuggestion =
        "You've snoozed several times. Consider taking a 5-minute break to recharge."
    public static let escalationGentle = "Your eyes and body will thank you for a quick break."
    public static let escalationInsistent = "A short break now prevents a longer recovery later."

    /// Get random message for nudge type
    public static func randomMessage(for type: NudgeType) -> String {
        switch type {
        case .blink:
            return blinkMessages.randomElement() ?? blinkMessages[0]
        case .posture:
            return postureMessages.randomElement() ?? postureMessages[0]
        case .miniExercise:
            return exercisePrompts.randomElement() ?? exercisePrompts[0]
        }
    }
}

// MARK: - Sound Assets

/// Sound asset references for nudges
public struct NudgeSounds {
    public static let blinkSoft = "blink_soft.wav"
    public static let postureChime = "posture_chime.wav"
    public static let exercisePrompt = "exercise_prompt.wav"
    public static let snooze = "snooze_confirm.wav"
    public static let escalation = "escalation_alert.wav"

    public static func soundFile(for type: NudgeType) -> String {
        switch type {
        case .blink: return blinkSoft
        case .posture: return postureChime
        case .miniExercise: return exercisePrompt
        }
    }
}

// MARK: - Nudge Configuration

/// Configuration for a specific nudge type
public struct NudgeConfig: Codable {
    public var enabled: Bool = true
    public var intervalSeconds: TimeInterval
    public var intervalVariance: TimeInterval = 0
    public var style: NudgeStyle = .normal
    public var soundEnabled: Bool = true

    public var effectiveInterval: TimeInterval {
        guard intervalVariance > 0 else { return intervalSeconds }
        let variance = TimeInterval.random(in: -intervalVariance...intervalVariance)
        return max(intervalSeconds + variance, 10)
    }
}

// MARK: - Snooze State

/// Tracks snooze state for a nudge type
public struct SnoozeState: Codable {
    public var snoozeCount: Int = 0
    public var lastSnoozeTime: Date?
    public var snoozeUntil: Date?

    public var isSnoozed: Bool {
        guard let until = snoozeUntil else { return false }
        return Date() < until
    }

    public mutating func snooze(for minutes: Int) {
        snoozeCount += 1
        lastSnoozeTime = Date()
        snoozeUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
    }

    public mutating func reset() {
        snoozeCount = 0
        lastSnoozeTime = nil
        snoozeUntil = nil
    }
}

// MARK: - Escalation Policy

/// Policy for handling repeated snoozes
public struct EscalationPolicy: Codable {
    public var enabled: Bool = true
    public var thresholdSnoozes: Int = 3
    public var action: EscalationAction = .suggestLongerBreak
    public var longerBreakMinutes: Int = 5

    public enum EscalationAction: String, Codable {
        case suggestLongerBreak
        case forceBreak
        case notify
    }
}

// MARK: - Micro Nudges Configuration

/// Complete configuration for micro-nudges system
public struct MicroNudgesConfig: Codable {
    public var enabled: Bool = true
    public var blink: NudgeConfig
    public var posture: NudgeConfig
    public var miniExercise: NudgeConfig

    public var snoozeEnabled: Bool = true
    public var defaultSnoozeDuration: Int = 5  // minutes
    public var snoozeOptions: [Int] = [5, 10, 15, 30]
    public var maxSnoozesPerNudge: Int = 3
    public var maxDailySnoozesTotal: Int = 15

    public var escalation: EscalationPolicy = EscalationPolicy()

    public static let `default` = MicroNudgesConfig(
        blink: NudgeConfig(intervalSeconds: 20, style: .subtle),
        posture: NudgeConfig(intervalSeconds: 25 * 60, intervalVariance: 5 * 60, style: .normal),
        miniExercise: NudgeConfig(
            intervalSeconds: 50 * 60, intervalVariance: 10 * 60, style: .prominent)
    )

    public func config(for type: NudgeType) -> NudgeConfig {
        switch type {
        case .blink: return blink
        case .posture: return posture
        case .miniExercise: return miniExercise
        }
    }
}

// MARK: - Nudge Event

/// A scheduled nudge event
public struct NudgeEvent: Identifiable {
    public let id = UUID()
    public let type: NudgeType
    public let message: String
    public let exercise: MiniExercise?
    public let timestamp: Date

    public init(type: NudgeType, message: String? = nil, exercise: MiniExercise? = nil) {
        self.type = type
        self.message = message ?? NudgeCopy.randomMessage(for: type)
        self.exercise = exercise
        self.timestamp = Date()
    }
}

// MARK: - Micro Nudges Manager

/// Manages micro-nudge scheduling and presentation
public final class MicroNudgesManager: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var isRunning = false
    @Published public private(set) var currentNudge: NudgeEvent?
    @Published public private(set) var snoozeStates: [NudgeType: SnoozeState] = [:]
    @Published public private(set) var dailySnoozeCount: Int = 0

    // MARK: - Configuration

    public var config: MicroNudgesConfig {
        didSet { updateTimers() }
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.sight.nudges", category: "MicroNudges")
    private var cancellables = Set<AnyCancellable>()

    // Combine timers for each nudge type
    private var blinkTimer: AnyCancellable?
    private var postureTimer: AnyCancellable?
    private var exerciseTimer: AnyCancellable?

    // Dispatch source timers (alternative)
    private var blinkDispatchTimer: DispatchSourceTimer?
    private var postureDispatchTimer: DispatchSourceTimer?
    private var exerciseDispatchTimer: DispatchSourceTimer?

    // SECURITY: Generation counters to prevent cancelled timer callbacks from firing
    private var postureTimerGeneration: Int = 0
    private var exerciseTimerGeneration: Int = 0

    private let timerQueue = DispatchQueue(label: "com.sight.nudges.timers", qos: .utility)

    // Callback for nudge events
    public var onNudge: ((NudgeEvent) -> Void)?
    public var onEscalation: ((String) -> Void)?

    // MARK: - Singleton

    public static let shared = MicroNudgesManager()

    // MARK: - Initialization

    public init(config: MicroNudgesConfig = .default) {
        // Load saved config
        if let savedConfig = Self.loadSavedConfig() {
            self.config = savedConfig
        } else {
            self.config = config
        }

        // Initialize snooze states
        if let savedStates = Self.loadSnoozeStates() {
            self.snoozeStates = savedStates
        } else {
            for type in NudgeType.allCases {
                snoozeStates[type] = SnoozeState()
            }
        }

        // Reset daily snooze count at midnight
        scheduleDailyReset()

        // Observe preferences changes
        setupPreferencesObservation()
    }

    // MARK: - Preferences Integration

    private func setupPreferencesObservation() {
        let preferences = PreferencesManager.shared

        // Observe blink reminder changes
        preferences.$blinkReminderEnabled
            .combineLatest(
                preferences.$blinkReminderIntervalSeconds, preferences.$blinkSoundEnabled
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled, interval, soundEnabled in
                self?.updateBlinkConfig(
                    enabled: enabled, interval: interval, soundEnabled: soundEnabled)
            }
            .store(in: &cancellables)

        // Observe posture reminder changes
        preferences.$postureReminderEnabled
            .combineLatest(
                preferences.$postureReminderIntervalSeconds, preferences.$postureSoundEnabled
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled, interval, soundEnabled in
                self?.updatePostureConfig(
                    enabled: enabled, interval: interval, soundEnabled: soundEnabled)
            }
            .store(in: &cancellables)
    }

    private func updateBlinkConfig(enabled: Bool, interval: Int, soundEnabled: Bool) {
        var newConfig = config
        newConfig.blink.enabled = enabled
        newConfig.blink.intervalSeconds = TimeInterval(interval)
        newConfig.blink.soundEnabled = soundEnabled
        config = newConfig
        logger.info(
            "Blink config updated: enabled=\(enabled), interval=\(interval)s, sound=\(soundEnabled)"
        )
    }

    private func updatePostureConfig(enabled: Bool, interval: Int, soundEnabled: Bool) {
        var newConfig = config
        newConfig.posture.enabled = enabled
        newConfig.posture.intervalSeconds = TimeInterval(interval)
        newConfig.posture.soundEnabled = soundEnabled
        config = newConfig
        logger.info(
            "Posture config updated: enabled=\(enabled), interval=\(interval)s, sound=\(soundEnabled)"
        )
    }

    /// Sync config from preferences (useful for initial sync)
    public func syncFromPreferences() {
        let prefs = PreferencesManager.shared
        updateBlinkConfig(
            enabled: prefs.blinkReminderEnabled,
            interval: prefs.blinkReminderIntervalSeconds,
            soundEnabled: prefs.blinkSoundEnabled)
        updatePostureConfig(
            enabled: prefs.postureReminderEnabled,
            interval: prefs.postureReminderIntervalSeconds,
            soundEnabled: prefs.postureSoundEnabled)
    }

    deinit {
        stop()
    }

    // MARK: - Persistence

    private static func loadSavedConfig() -> MicroNudgesConfig? {
        guard let data = UserDefaults.standard.data(forKey: "MicroNudgesConfig"),
            let config = try? JSONDecoder().decode(MicroNudgesConfig.self, from: data)
        else { return nil }
        return config
    }

    public func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "MicroNudgesConfig")
        }
    }

    private static func loadSnoozeStates() -> [NudgeType: SnoozeState]? {
        guard let data = UserDefaults.standard.data(forKey: "NudgeSnoozeStates"),
            let states = try? JSONDecoder().decode([NudgeType: SnoozeState].self, from: data)
        else { return nil }
        return states
    }

    private func saveSnoozeStates() {
        if let data = try? JSONEncoder().encode(snoozeStates) {
            UserDefaults.standard.set(data, forKey: "NudgeSnoozeStates")
        }
    }

    // MARK: - Public API

    /// Start nudge scheduling
    public func start() {
        guard !isRunning else { return }

        isRunning = true
        logger.info("Starting micro-nudges")

        startTimers()
    }

    /// Stop all nudges
    public func stop() {
        isRunning = false

        blinkTimer?.cancel()
        postureTimer?.cancel()
        exerciseTimer?.cancel()

        blinkDispatchTimer?.cancel()
        postureDispatchTimer?.cancel()
        exerciseDispatchTimer?.cancel()

        logger.info("Stopped micro-nudges")
    }

    /// Snooze current nudge
    public func snooze(_ type: NudgeType, for minutes: Int? = nil) {
        let duration = minutes ?? config.defaultSnoozeDuration

        snoozeStates[type]?.snooze(for: duration)
        dailySnoozeCount += 1
        saveSnoozeStates()  // Persist

        logger.info("Snoozed \(type.rawValue) for \(duration) minutes")

        // Check for escalation
        if let state = snoozeStates[type], state.snoozeCount >= config.escalation.thresholdSnoozes {
            handleEscalation(for: type, snoozeCount: state.snoozeCount)
        }

        currentNudge = nil
    }

    /// Dismiss current nudge (completed)
    public func dismiss() {
        if let nudge = currentNudge {
            snoozeStates[nudge.type]?.reset()
            saveSnoozeStates()  // Persist
        }
        currentNudge = nil
    }

    // MARK: - Timer Management

    private func startTimers() {
        // Blink timer using Combine
        if config.blink.enabled {
            startBlinkTimer()
        }

        // Posture timer using DispatchSourceTimer for variance
        if config.posture.enabled {
            schedulePostureTimer()
        }

        // Exercise timer using DispatchSourceTimer
        if config.miniExercise.enabled {
            scheduleExerciseTimer()
        }
    }

    private func updateTimers() {
        saveConfig()  // Persist on change
        stop()
        if config.enabled {
            start()
        }
    }

    // MARK: - Combine Timer (Blink)

    private func startBlinkTimer() {
        blinkTimer = Timer.publish(
            every: config.blink.intervalSeconds,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.triggerNudge(.blink)
        }
    }

    // MARK: - DispatchSourceTimer (Posture/Exercise)

    private func schedulePostureTimer() {
        let interval = config.posture.effectiveInterval

        // SECURITY: Increment generation to invalidate any pending callbacks
        postureTimerGeneration += 1
        let currentGeneration = postureTimerGeneration

        postureDispatchTimer?.cancel()
        postureDispatchTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        postureDispatchTimer?.schedule(deadline: .now() + interval)
        postureDispatchTimer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                // SECURITY: Only fire if generation matches (timer wasn't replaced)
                guard let self = self, self.postureTimerGeneration == currentGeneration else {
                    return
                }
                self.triggerNudge(.posture)
                self.schedulePostureTimer()  // Reschedule with variance
            }
        }
        postureDispatchTimer?.resume()
    }

    private func scheduleExerciseTimer() {
        let interval = config.miniExercise.effectiveInterval

        // SECURITY: Increment generation to invalidate any pending callbacks
        exerciseTimerGeneration += 1
        let currentGeneration = exerciseTimerGeneration

        exerciseDispatchTimer?.cancel()
        exerciseDispatchTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        exerciseDispatchTimer?.schedule(deadline: .now() + interval)
        exerciseDispatchTimer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                // SECURITY: Only fire if generation matches (timer wasn't replaced)
                guard let self = self, self.exerciseTimerGeneration == currentGeneration else {
                    return
                }
                self.triggerNudge(.miniExercise)
                self.scheduleExerciseTimer()  // Reschedule with variance
            }
        }
        exerciseDispatchTimer?.resume()
    }

    // MARK: - Nudge Triggering

    private func triggerNudge(_ type: NudgeType) {
        guard config.enabled else { return }
        guard config.config(for: type).enabled else { return }

        // Check if snoozed
        if snoozeStates[type]?.isSnoozed == true {
            logger.debug("\(type.rawValue) is snoozed, skipping")
            return
        }

        // Create nudge event
        let exercise: MiniExercise? =
            (type == .miniExercise)
            ? MiniExercise.defaults.randomElement()
            : nil

        let event = NudgeEvent(type: type, exercise: exercise)

        DispatchQueue.main.async {
            self.currentNudge = event
            self.onNudge?(event)
        }

        logger.info("Triggered \(type.rawValue): \(event.message)")
    }

    // MARK: - Escalation

    private func handleEscalation(for type: NudgeType, snoozeCount: Int) {
        guard config.escalation.enabled else { return }

        logger.warning("Escalation triggered for \(type.rawValue) after \(snoozeCount) snoozes")

        switch config.escalation.action {
        case .suggestLongerBreak:
            let message = NudgeCopy.escalationSuggestion
            onEscalation?(message)

        case .forceBreak:
            // Trigger a longer break
            onEscalation?("Taking a \(config.escalation.longerBreakMinutes) minute break")

        case .notify:
            sendEscalationNotification()
        }
    }

    private func sendEscalationNotification() {
        // Skip if running without bundle ID (dev mode)
        guard Bundle.main.bundleIdentifier != nil else {
            logger.warning("Escalation notification skipped (no bundle ID)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time for a Real Break"
        content.body = NudgeCopy.escalationSuggestion
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "sight.escalation-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error(
                    "Failed to send escalation notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Daily Reset

    private func scheduleDailyReset() {
        // Calculate time until midnight
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
            let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow)
        else {
            // SECURITY: Schedule retry in 1 hour if calculation fails
            DispatchQueue.main.asyncAfter(deadline: .now() + 3600) { [weak self] in
                self?.scheduleDailyReset()
            }
            return
        }

        // SECURITY: Ensure minimum interval to prevent runaway scheduling during DST transitions
        let rawInterval = midnight.timeIntervalSinceNow
        let interval = max(60, rawInterval)  // At least 60 seconds

        if rawInterval < 60 {
            logger.warning(
                "Daily reset interval unexpectedly short (\(rawInterval)s), using 60s minimum")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.resetDailyCounts()
            self?.scheduleDailyReset()  // Schedule next reset
        }
    }

    private func resetDailyCounts() {
        dailySnoozeCount = 0
        for type in NudgeType.allCases {
            snoozeStates[type]?.reset()
        }
        saveSnoozeStates()  // Persist
        logger.info("Daily nudge counts reset")
    }
}

// MARK: - Testing Scenarios

/*
 Testing Scenarios for Micro-Nudges:

 1. Basic Blink Nudge
    - Start manager
    - Wait 20 seconds
    - Verify blink nudge triggered
    - Dismiss
    - Verify snoozeCount reset to 0

 2. Snooze Flow
    - Trigger posture nudge
    - Snooze for 5 minutes
    - Verify nudge dismissed
    - Verify snoozeCount incremented
    - Wait 5 minutes
    - Verify nudge triggers again

 3. Escalation After 3 Snoozes
    - Trigger posture nudge
    - Snooze 3 times
    - Verify escalation triggered
    - Verify escalation message shown

 4. Daily Snooze Limit
    - Snooze various nudges 15 times
    - Verify max limit warning

 5. Interval Variance
    - Configure posture with 5 min variance
    - Start multiple times
    - Verify intervals vary within range

 6. Disable During Smart Pause
    - Enable SmartPause meeting detection
    - Trigger meeting app
    - Verify nudges paused
*/
