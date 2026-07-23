import AppKit
import Combine
import Foundation
import os.log

extension TimerStateMachine {

    // MARK: - Preferences Binding

    internal func setupPreferencesBinding() {
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


}
