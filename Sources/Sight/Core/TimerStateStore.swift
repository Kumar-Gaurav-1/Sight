import Foundation
import os.log

/// Persists and restores timer state for crash recovery
/// Saves state to UserDefaults on transitions and periodically during active sessions
public final class TimerStateStore {

    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "StateStore")
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasPersistedState = "timerHasPersistedState"
        static let currentState = "timerCurrentState"
        static let remainingSeconds = "timerRemainingSeconds"
        static let isPaused = "timerIsPaused"
        static let pauseSource = "timerPauseSource"
        static let stateStartTime = "timerStateStartTime"
        static let configuration = "timerConfiguration"
        static let lastSaveTime = "timerLastSaveTime"
    }

    public static let shared = TimerStateStore()

    private init() {}

    // MARK: - Save State

    /// Save complete timer state
    public func saveState(
        state: String,
        remainingSeconds: Int,
        isPaused: Bool,
        pauseSource: String?,
        configuration: TimerConfiguration
    ) {
        defaults.set(true, forKey: Keys.hasPersistedState)
        defaults.set(state, forKey: Keys.currentState)
        defaults.set(remainingSeconds, forKey: Keys.remainingSeconds)
        defaults.set(isPaused, forKey: Keys.isPaused)
        defaults.set(pauseSource, forKey: Keys.pauseSource)
        defaults.set(Date(), forKey: Keys.lastSaveTime)

        // Save configuration
        let configDict: [String: Int] = [
            "workInterval": configuration.workIntervalSeconds,
            "preBreak": configuration.preBreakSeconds,
            "breakDuration": configuration.breakDurationSeconds,
        ]
        defaults.set(configDict, forKey: Keys.configuration)

        logger.debug("Timer state saved: \(state), \(remainingSeconds)s remaining")
    }

    /// Quick save of remaining time (for periodic updates)
    public func updateRemainingTime(_ seconds: Int) {
        guard defaults.bool(forKey: Keys.hasPersistedState) else { return }
        defaults.set(seconds, forKey: Keys.remainingSeconds)
        defaults.set(Date(), forKey: Keys.lastSaveTime)
    }

    // MARK: - Load State

    /// Check if there's valid persisted state
    public func hasPersistedState() -> Bool {
        guard defaults.bool(forKey: Keys.hasPersistedState) else { return false }

        // Check if state is recent (within last 24 hours)
        if let lastSave = defaults.object(forKey: Keys.lastSaveTime) as? Date {
            let hoursSinceSave = Date().timeIntervalSince(lastSave) / 3600
            if hoursSinceSave > 24 {
                logger.info("Persisted state too old (\(hoursSinceSave)h), ignoring")
                return false
            }
        }

        return true
    }

    /// Load persisted state
    public func loadState() -> PersistedTimerState? {
        guard hasPersistedState() else { return nil }

        guard let stateString = defaults.string(forKey: Keys.currentState),
            let configDict = defaults.dictionary(forKey: Keys.configuration) as? [String: Int],
            let workInterval = configDict["workInterval"],
            let preBreak = configDict["preBreak"],
            let breakDuration = configDict["breakDuration"]
        else {
            logger.warning("Failed to load persisted state - incomplete data")
            return nil
        }

        let state = PersistedTimerState(
            state: stateString,
            remainingSeconds: defaults.integer(forKey: Keys.remainingSeconds),
            isPaused: defaults.bool(forKey: Keys.isPaused),
            pauseSource: defaults.string(forKey: Keys.pauseSource),
            configuration: TimerConfiguration(
                workIntervalSeconds: workInterval,
                preBreakSeconds: preBreak,
                breakDurationSeconds: breakDuration
            ),
            savedAt: defaults.object(forKey: Keys.lastSaveTime) as? Date ?? Date()
        )

        logger.info("Loaded persisted state: \(stateString), \(state.remainingSeconds)s remaining")
        return state
    }

    // MARK: - Clear State

    /// Clear all persisted state (called after successful restore or on normal exit)
    public func clearState() {
        defaults.removeObject(forKey: Keys.hasPersistedState)
        defaults.removeObject(forKey: Keys.currentState)
        defaults.removeObject(forKey: Keys.remainingSeconds)
        defaults.removeObject(forKey: Keys.isPaused)
        defaults.removeObject(forKey: Keys.pauseSource)
        defaults.removeObject(forKey: Keys.stateStartTime)
        defaults.removeObject(forKey: Keys.configuration)
        defaults.removeObject(forKey: Keys.lastSaveTime)

        logger.debug("Persisted state cleared")
    }
}

// MARK: - Persisted State Model

public struct PersistedTimerState {
    public let state: String
    public let remainingSeconds: Int
    public let isPaused: Bool
    public let pauseSource: String?
    public let configuration: TimerConfiguration
    public let savedAt: Date

    /// Human-readable description of saved state
    public var description: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        let timeStr = minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"

        if isPaused {
            return "Paused in \(state) state with \(timeStr) remaining"
        } else {
            return "Active \(state) state with \(timeStr) remaining"
        }
    }

    /// Check if state is still relevant (not too old)
    public var isStale: Bool {
        let hoursSinceSave = Date().timeIntervalSince(savedAt) / 3600
        return hoursSinceSave > 1  // State older than 1 hour is probably stale
    }
}
