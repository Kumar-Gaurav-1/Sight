import AppKit
import Combine
import Foundation
import os.log

extension TimerStateMachine {

    // MARK: - State Transitions

    internal func transitionTo(_ newState: TimerState) {
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

    internal func startTimer(duration: Int) {
        // SECURITY: Defensive cancel - in case previous timer wasn't properly cancelled
        timerCancellable?.cancel()

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    internal func tick() {

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

    internal func advanceState() {
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

    internal func advanceAfterBreak() {
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


}
