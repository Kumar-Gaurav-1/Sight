import AppKit
import Combine
import Foundation
import os.log

extension TimerStateMachine {

    // MARK: - State Persistence

    /// Save current timer state for crash recovery
    internal func saveCurrentState() {
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


}
