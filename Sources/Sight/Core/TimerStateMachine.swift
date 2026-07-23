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

    @Published public internal(set) var currentState: TimerState = .idle
    @Published public internal(set) var remainingSeconds: Int = 0
    @Published public internal(set) var isPaused: Bool = false
    @Published public internal(set) var pauseSource: PauseSource? = nil

    /// Count of breaks taken in current session (for long breaks)
    @Published public internal(set) var breakCount: Int = 0

    /// Time elapsed since break started (for skip difficulty)
    @Published public internal(set) var breakElapsedSeconds: Int = 0

    /// Time elapsed in current work period (for overtime nudge)
    @Published public internal(set) var workElapsedSeconds: Int = 0

    /// Track if overtime nudge was already shown this work period
    internal var overtimeNudgeShown: Bool = false

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

    @MainActor public static var shared: TimerStateMachine!

    // MARK: - Private Properties

    internal var timerCancellable: AnyCancellable?
    internal var cancellables = Set<AnyCancellable>()
    internal var stateStartTime: Date?
    internal var pausedRemainingSeconds: Int = 0
    internal var pausedState: TimerState?
    internal let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "StateMachine")

    // System observers
    internal var wakeObserver: NSObjectProtocol?
    internal var sleepObserver: NSObjectProtocol?

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

}
