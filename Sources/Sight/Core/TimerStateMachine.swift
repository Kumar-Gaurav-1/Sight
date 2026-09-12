import AppKit
import Combine
import Foundation
import os.log

/// Combine-based state machine for timer management
/// Supports 20-20-20 eye care mode
/// SECURITY: @MainActor ensures all state mutations occur on main thread
@MainActor
public final class TimerStateMachine: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var currentState: TimerState = .idle
    @Published public private(set) var remainingSeconds: Int = 0
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var pauseSource: PauseSource? = nil

    /// Count of breaks taken in current session (for long breaks)
    @Published public private(set) var breakCount: Int = 0

    /// Time elapsed since break started (for skip difficulty)
    @Published public private(set) var breakElapsedSeconds: Int = 0

    /// Time elapsed in current work period (for overtime nudge)
    @Published public private(set) var workElapsedSeconds: Int = 0

    /// Track if overtime nudge was already shown this work period
    private var overtimeNudgeShown: Bool = false

    /// Who triggered the pause
    public enum PauseSource: String {
        case user  // Manual pause via UI
        case smartPause  // SmartPauseManager (meetings, screen recording, etc.)
        case workHours  // WorkHoursManager (quiet hours, rest day)
        case idle  // IdleDetector (user away)
        case system  // System sleep/wake
    }

    /// Whether user can skip based on skip difficulty setting
    public var canSkipBreak: Bool {
        let difficulty = PreferencesManager.shared.breakSkipDifficulty
        switch difficulty {
        case "casual":
            return true  // Can skip anytime
        case "balanced":
            return breakElapsedSeconds >= 5  // Can skip after a pause
        case "hardcore":
            return false  // No skips allowed
        default:
            return true
        }
    }

    /// Whether the current break is a long break
    public var isLongBreak: Bool {
        guard PreferencesManager.shared.longBreakEnabled else { return false }
        let interval = PreferencesManager.shared.longBreakInterval
        return breakCount > 0 && breakCount % interval == 0
    }

    // MARK: - Configuration

    public var configuration: TimerConfiguration {
        didSet {
            if currentState != .idle && !isPaused {
                logger.info("Configuration changed, will apply on next cycle")
            }
        }
    }

    /// Whether to call Renderer methods during state transitions
    public var rendererEnabled: Bool = true

    /// Whether to send system notifications
    public var notificationsEnabled: Bool = true

    // MARK: - Singleton

    nonisolated(unsafe) public static var shared: TimerStateMachine!

    // MARK: - Private Properties

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var stateStartTime: Date?
    private var pausedRemainingSeconds: Int = 0
    private var pausedState: TimerState?
    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "StateMachine")

    // System observers
    private var wakeObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init(configuration: TimerConfiguration = .default, rendererEnabled: Bool = true) {
        self.configuration = configuration
        self.rendererEnabled = rendererEnabled
        setupPreferencesBinding()
        setupSystemObservers()
    }

    deinit {
        // SECURITY: Remove observers directly without MainActor context
        // Observer removal is thread-safe in NotificationCenter
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - System Observers

    private func setupSystemObservers() {
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

    private func removeSystemObservers() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func handleSystemWake() {
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

    private func handleSystemSleep() {
        logger.info("System sleep detected")

        // Only pause if timer is running (not already paused)
        // Mark this as a system pause so we know to resume on wake
        if currentState != .idle && !isPaused {
            logger.info("Pausing timer for system sleep")
            pause(source: .system)
        }
    }

    // MARK: - Preferences Binding

    private func setupPreferencesBinding() {
        PreferencesManager.shared.$workIntervalSeconds
            .merge(
                with: PreferencesManager.shared.$breakDurationSeconds,
                PreferencesManager.shared.$preBreakSeconds
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configuration = PreferencesManager.shared.timerConfiguration
                self?.logger.info("Configuration updated from preferences")
            }
            .store(in: &cancellables)

        // Meeting detection - pause during meetings
        MeetingDetector.shared.$isInMeeting
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inMeeting in
                guard let self = self else { return }

                // Pause during meetings - only if in work state and not already paused
                if inMeeting && self.currentState == .work && !self.isPaused {
                    self.logger.info(
                        "Pausing for meeting: \(MeetingDetector.shared.currentMeeting ?? "Unknown")"
                    )
                    self.pause(source: .smartPause)
                } else if !inMeeting && self.isPaused && self.pauseSource == .smartPause {
                    // Resume only if WE (meeting detection) were the one who paused it
                    // Check pausedState to see what state we were in before pause
                    // Only resume if we were in work state (don't resume breaks, preBreaks)
                    if self.pausedState == .work || self.currentState == .work {
                        self.logger.info("Meeting ended, resuming timer")
                        self.resume()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    public func start() {
        guard currentState == .idle else {
            logger.warning("Cannot start: already in state \(self.currentState.rawValue)")
            return
        }

        isPaused = false
        logger.info("Starting timer (mode: \(self.configuration.mode.rawValue))")

        // Track session start for statistics
        StatisticsEngine.shared.startSession()

        transitionTo(.work)
    }

    public func stop() {
        logger.info("Stopping timer from state \(self.currentState.rawValue)")
        timerCancellable?.cancel()
        timerCancellable = nil
        currentState = .idle
        remainingSeconds = 0
        isPaused = false
        pausedState = nil
        pausedRemainingSeconds = 0

        // Track session end for statistics
        StatisticsEngine.shared.endSession()

        // Clear persisted state on normal stop
        TimerStateStore.shared.clearState()
    }

    /// Pause the timer (preserves state)
    /// - Parameter source: Who/what triggered the pause
    public func pause(source: PauseSource = .user) {
        guard currentState != .idle && !isPaused else { return }

        logger.info(
            "Pausing timer at \(self.remainingSeconds)s remaining (source: \(source.rawValue))")
        pausedState = currentState
        pausedRemainingSeconds = remainingSeconds
        isPaused = true
        pauseSource = source
        timerCancellable?.cancel()
        timerCancellable = nil

        // Track pause event for statistics
        let pauseReason = mapToPauseReason(source)
        StatisticsEngine.shared.startPause(reason: pauseReason)
    }

    /// Map PauseSource to PauseReason for statistics
    private func mapToPauseReason(_ source: PauseSource) -> PauseReason {
        switch source {
        case .user: return .manual
        case .smartPause: return .meeting
        case .workHours: return .quietHours
        case .idle: return .idle
        case .system: return .systemSleep
        }
    }

    /// Resume from pause
    /// - Parameter clearSource: If true, clears pauseSource (default). Set false to preserve for logging.
    public func resume(clearSource: Bool = true) {
        guard isPaused, let savedState = pausedState else { return }

        logger.info(
            "Resuming timer from \(savedState.rawValue) with \(self.pausedRemainingSeconds)s remaining"
        )

        // End pause tracking for statistics
        StatisticsEngine.shared.endPause()

        isPaused = false
        if clearSource { pauseSource = nil }
        currentState = savedState
        remainingSeconds = pausedRemainingSeconds
        pausedState = nil
        startTimer(duration: remainingSeconds)
    }

    public func toggle() {
        if currentState == .idle {
            start()
        } else if isPaused {
            resume()
        } else {
            pause()
        }
    }

    public func reset() {
        logger.info("Resetting timer cycle")
        stop()
        start()
    }

    public func skipToNext() {
        // Cancel any pending timer immediately
        timerCancellable?.cancel()
        timerCancellable = nil

        if currentState == .break {
            logger.info("Break skipped by user")
            AdherenceManager.shared.recordBreak(
                completed: false, duration: configuration.breakDurationSeconds)

            // CRITICAL: Hide overlay immediately when skipping break
            // This prevents the overlay's auto-hide timer from firing and causing double-skip
            if rendererEnabled {
                Renderer.hideOverlay()
            }

            // Play break end sound since we're ending the break
            SoundManager.shared.playBreakEnd()

            // Transition directly to work (no delay needed since user initiated)
            transitionTo(.work)
            return
        }

        if currentState == .preBreak {
            // "Skip" during countdown means skip the break entirely, not start it
            logger.info("Pre-break skipped by user - returning to work")

            // Hide any pre-break overlay/countdown
            if rendererEnabled {
                Renderer.hideOverlay()
            }

            // Record as skipped break
            AdherenceManager.shared.recordBreak(
                completed: false, duration: configuration.breakDurationSeconds)

            // Return to work with full work interval
            transitionTo(.work)
            return
        }

        switch currentState {
        case .idle:
            start()
        case .work:
            transitionTo(.preBreak)
        case .preBreak, .break:
            // Already handled above
            break
        }
    }

    /// Postpone the next break by adding extra time
    /// - Parameter minutes: Number of minutes to add
    public func postpone(minutes: Int) {
        guard currentState == .work || currentState == .preBreak else {
            logger.warning("Cannot postpone in state: \(self.currentState.rawValue)")
            return
        }

        let additionalSeconds = minutes * 60

        if currentState == .preBreak {
            // Go back to work state with additional time
            logger.info("Postponing break by \(minutes) minutes from pre-break")

            // Hide any pre-break overlay/notification
            if rendererEnabled {
                Renderer.hideOverlay()
            }

            timerCancellable?.cancel()
            remainingSeconds = additionalSeconds
            currentState = .work
            startTimer(duration: additionalSeconds)
        } else {
            // Add time to existing work timer
            logger.info(
                "Postponing break by \(minutes) minutes, adding to \(self.remainingSeconds)s")
            remainingSeconds += additionalSeconds
        }
    }

    // MARK: - State Transitions

    private func transitionTo(_ newState: TimerState) {
        let oldState = currentState
        logger.info("Transitioning: \(oldState.rawValue) → \(newState.rawValue)")

        timerCancellable?.cancel()
        currentState = newState
        stateStartTime = Date()

        let duration: Int
        switch newState {
        case .idle:
            remainingSeconds = 0
            return

        case .work:
            duration = configuration.workIntervalSeconds

            // NOTE: Sound is NOT played here anymore for break->work transitions
            // It's played in skipToNext() and advanceState() where it's more explicit
            // This prevents double-play when skipToNext() calls transitionTo(.work)

            // Send notification if coming from break
            if oldState == .break && notificationsEnabled {
                NotificationManager.shared.sendBreakEndNotification()
            }

        case .preBreak:
            // Use countdown duration from preferences
            duration = PreferencesManager.shared.countdownDuration

            if rendererEnabled {
                Renderer.showPreBreak(preSeconds: duration)
            }

            if notificationsEnabled {
                NotificationManager.shared.sendPreBreakNotification(secondsRemaining: duration)
            }

        case .break:
            // Increment break counter
            breakCount += 1
            breakElapsedSeconds = 0

            // Reset overtime tracking for fresh start after break
            workElapsedSeconds = 0
            overtimeNudgeShown = false

            // Use longer duration if this is a long break
            if isLongBreak {
                duration = PreferencesManager.shared.longBreakDurationSeconds
                logger.info(
                    "Starting LONG break #\(self.breakCount) (every \(PreferencesManager.shared.longBreakInterval)th)"
                )
            } else {
                duration = configuration.breakDurationSeconds
            }

            // Play break start sound
            SoundManager.shared.playBreakStart()

            if rendererEnabled {
                Renderer.showBreak(durationSeconds: duration)
            }

            if notificationsEnabled {
                NotificationManager.shared.sendBreakStartNotification(durationSeconds: duration)
            }

            // Lock Mac if enabled - forces user to step away
            if PreferencesManager.shared.lockMacOnBreak {
                lockScreen()
            }
        }

        remainingSeconds = duration
        startTimer(duration: duration)

        // Save state for crash recovery
        saveCurrentState()
    }

    private func startTimer(duration: Int) {
        // SECURITY: Defensive cancel - in case previous timer wasn't properly cancelled
        timerCancellable?.cancel()

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {

        // Skip if manually paused
        if isPaused {
            // Check if we should auto-resume (schedule cleared)
            if !WorkHoursManager.shared.shouldPause() && pausedState != nil {
                // Schedule cleared - auto resume
                resume()
            }
            return
        }

        // Only pause during work state (not during breaks)
        if currentState == .work && WorkHoursManager.shared.shouldPause() {
            // During quiet hours or non-active days, pause automatically
            pause(source: .workHours)
            return
        }

        remainingSeconds -= 1

        // Track elapsed time during breaks (for skip difficulty)
        if currentState == .break {
            breakElapsedSeconds += 1
        }

        // Track elapsed work time (for overtime nudge)
        if currentState == .work {
            workElapsedSeconds += 1

            // Sync screen time every 60 seconds
            if workElapsedSeconds % 60 == 0 {
                let totalMinutes = StatisticsEngine.shared.todayScreenTimeMinutes
                AdherenceManager.shared.recordScreenTime(minutes: totalMinutes)
            }

            // Check for overtime nudge trigger
            let prefs = PreferencesManager.shared
            if prefs.overtimeNudgeEnabled && !overtimeNudgeShown {
                // Show overtime nudge if working past configured interval
                let workInterval = configuration.workIntervalSeconds
                // Trigger overtime nudge when elapsed >= 1.5x work interval (e.g., 30 min for 20-20-20)
                let overtimeThreshold = Int(Double(workInterval) * 1.5)
                if workElapsedSeconds >= overtimeThreshold {
                    logger.info("Showing overtime nudge after \\(workElapsedSeconds)s of work")
                    overtimeNudgeShown = true
                    if rendererEnabled {
                        Renderer.showOvertimeNudge(elapsedMinutes: workElapsedSeconds / 60)
                    }
                    if prefs.overtimeNudgeSoundEnabled {
                        SoundManager.shared.playNudge()
                    }
                    // Send notification
                    NotificationManager.shared.sendOvertimeNotification(
                        minutesPast: workElapsedSeconds / 60)
                }
            }
        }

        // Also check overtime nudge when paused (if overtimeShowWhenPaused is enabled)
        if isPaused && PreferencesManager.shared.overtimeShowWhenPaused && !overtimeNudgeShown {
            let prefs = PreferencesManager.shared
            if prefs.overtimeNudgeEnabled {
                let workInterval = configuration.workIntervalSeconds
                let overtimeThreshold = Int(Double(workInterval) * 1.5)
                if workElapsedSeconds >= overtimeThreshold {
                    logger.info("Showing overtime nudge while paused after \\(workElapsedSeconds)s")
                    overtimeNudgeShown = true
                    if rendererEnabled {
                        Renderer.showOvertimeNudge(elapsedMinutes: workElapsedSeconds / 60)
                    }
                }
            }
        }

        if remainingSeconds <= 0 {
            advanceState()
        }
    }

    private func advanceState() {
        switch currentState {
        case .idle:
            break
        case .work:
            // Skip preBreak if disabled or duration is 0
            let countdownEnabled = PreferencesManager.shared.countdownEnabled
            let countdownDuration = PreferencesManager.shared.countdownDuration
            if !countdownEnabled || countdownDuration <= 0 {
                transitionTo(.break)
            } else {
                transitionTo(.preBreak)
            }
        case .preBreak:
            transitionTo(.break)
        case .break:
            logger.info("Break completed naturally")

            // Cancel any pending timer first
            timerCancellable?.cancel()
            timerCancellable = nil

            AdherenceManager.shared.recordBreak(
                completed: true, duration: configuration.breakDurationSeconds)

            // Play break end sound
            if PreferencesManager.shared.breakEndSoundEnabled {
                SoundManager.shared.playBreakEnd()
            }

            // Hide overlay BEFORE transitioning to prevent race condition
            if rendererEnabled {
                Renderer.hideOverlay()
            }

            // Small delay to ensure overlay is fully hidden before starting work timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.advanceAfterBreak()
            }
        }
    }

    private func advanceAfterBreak() {
        // Guard against being called while in middle of another break
        guard currentState == .break else {
            logger.warning(
                "advanceAfterBreak called but state is \(self.currentState.rawValue), ignoring")
            return
        }

        // Reset wellness reminder timers after break if enabled
        MicroNudgesManager.shared.resetAfterBreak()

        transitionTo(.work)
    }

    // MARK: - State Persistence

    /// Save current timer state for crash recovery
    private func saveCurrentState() {
        guard currentState != .idle else {
            TimerStateStore.shared.clearState()
            return
        }

        TimerStateStore.shared.saveState(
            state: currentState.rawValue,
            remainingSeconds: remainingSeconds,
            isPaused: isPaused,
            pauseSource: pauseSource?.rawValue,
            configuration: configuration
        )
    }

    // MARK: - Screen Lock

    /// Lock the screen to force user to step away during break
    private func lockScreen() {
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
