import AppKit
import Combine
import Foundation
import os.log

extension TimerStateMachine {

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
    internal func mapToPauseReason(_ source: PauseSource) -> PauseReason {
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


}
