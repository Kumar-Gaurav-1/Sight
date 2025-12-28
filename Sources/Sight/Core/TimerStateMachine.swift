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

    /// Who triggered the pause
    public enum PauseSource: String {
        case user  // Manual pause via UI
        case smartPause  // SmartPauseManager (meetings, screen recording, etc.)
        case workHours  // WorkHoursManager (quiet hours, rest day)
        case idle  // IdleDetector (user away)
        case system  // System sleep/wake
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

    // MARK: - Private Properties

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var stateStartTime: Date?
    private var pausedRemainingSeconds: Int = 0
    private var pausedState: TimerState?
    private let logger = Logger(subsystem: "com.sight", category: "StateMachine")

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

        // If we were paused due to sleep, resume
        if isPaused && currentState != .idle {
            resume()
        }
    }

    private func handleSystemSleep() {
        logger.info("System sleep detected")

        // Pause if running
        if currentState != .idle && !isPaused {
            pause()
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
    }

    /// Resume from pause
    /// - Parameter clearSource: If true, clears pauseSource (default). Set false to preserve for logging.
    public func resume(clearSource: Bool = true) {
        guard isPaused, let savedState = pausedState else { return }

        logger.info(
            "Resuming timer from \(savedState.rawValue) with \(self.pausedRemainingSeconds)s remaining"
        )
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

        switch currentState {
        case .idle:
            start()
        case .work:
            transitionTo(.preBreak)
        case .preBreak:
            transitionTo(.break)
        case .break:
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
            duration = configuration.preBreakSeconds

            if rendererEnabled {
                Renderer.showPreBreak(preSeconds: duration)
            }

            if notificationsEnabled {
                NotificationManager.shared.sendPreBreakNotification(secondsRemaining: duration)
            }

        case .break:
            duration = configuration.breakDurationSeconds

            // Play break start sound
            SoundManager.shared.playBreakStart()

            if rendererEnabled {
                Renderer.showBreak(durationSeconds: duration)
            }

            if notificationsEnabled {
                NotificationManager.shared.sendBreakStartNotification(durationSeconds: duration)
            }
        }

        remainingSeconds = duration
        startTimer(duration: duration)
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

        if remainingSeconds <= 0 {
            advanceState()
        }
    }

    private func advanceState() {
        switch currentState {
        case .idle:
            break
        case .work:
            // Skip preBreak if duration is 0 (disabled)
            if configuration.preBreakSeconds <= 0 {
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
        transitionTo(.work)
    }
}
