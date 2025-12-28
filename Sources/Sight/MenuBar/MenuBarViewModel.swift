import AppKit
import Combine
import Foundation

@MainActor
public final class MenuBarViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var currentState: TimerState = .idle
    @Published public private(set) var remainingSeconds: Int = 0
    @Published public private(set) var strainLevel: Float = 0.0  // 0.0 to 1.0
    @Published public private(set) var connectionState: Bool = false

    // Derived UI Properties
    @Published public private(set) var statusIconName: String = "eye.slash"
    @Published public private(set) var statusLabel: String? = nil
    @Published public private(set) var hudTitle: String = "Monitoring Paused"

    @Published public private(set) var hudDetail: String = ""

    // New Dashboard Properties
    @Published public private(set) var progress: Double = 1.0
    @Published public private(set) var nextBreakText: String? = nil
    @Published public private(set) var dailyBreaks: Int = 0
    @Published public private(set) var isPaused: Bool = false

    // MARK: - Dependencies

    private let stateMachine: TimerStateMachine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(stateMachine: TimerStateMachine) {
        self.stateMachine = stateMachine
        setupBindings()

        // Initial state
        self.currentState = stateMachine.currentState
        self.remainingSeconds = stateMachine.remainingSeconds
        updateDerivedProperties()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Bind state machine changes (state, seconds, and paused)
        stateMachine.$currentState
            .combineLatest(stateMachine.$remainingSeconds, stateMachine.$isPaused)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, seconds, paused in
                self?.currentState = state
                self?.remainingSeconds = seconds
                self?.isPaused = paused
                self?.updateDerivedProperties()
            }
            .store(in: &cancellables)

        // Strain Level update (stored timer for proper cleanup)
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateStrain()
            }
            .store(in: &cancellables)

        // Observe Daily Stats
        AdherenceManager.shared.$todayStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.dailyBreaks = stats.breaksCompleted
            }
            .store(in: &cancellables)
    }

    // MARK: - Logic

    private func updateDerivedProperties() {

        switch currentState {
        case .idle:
            statusIconName = "circle"
            statusLabel = "Paused"
            hudTitle = "Monitoring Paused"
            hudDetail = "Ready to focus?"

        case .work:
            statusIconName = "circle.fill"
            let timeStr = formatTimeCompact(remainingSeconds)
            statusLabel = timeStr
            hudTitle = "Working"
            hudDetail = "Next break in \(formatTime(remainingSeconds))"

        case .preBreak:
            statusIconName = "exclamationmark.triangle"
            statusLabel = formatTimeCompact(remainingSeconds)
            hudTitle = "Break in \(remainingSeconds)s"
            hudDetail = "Wrap up your work"

        case .break:
            statusIconName = "cup.and.saucer"
            statusLabel = "Break"
            hudTitle = "On Break"
            hudDetail = "Relax those eyes..."
            // SECURITY: Guard against division by zero
            let breakDuration = Double(stateMachine.configuration.breakDurationSeconds)
            if breakDuration > 0 {
                progress = 1.0 - (Double(remainingSeconds) / breakDuration)
            } else {
                progress = 1.0
            }
            nextBreakText = nil
        }

        // Calculate Progress (Work)
        if currentState == .work {
            let total = Double(stateMachine.configuration.workIntervalSeconds)
            // SECURITY: Guard against division by zero
            if total > 0 {
                progress = max(0.0, min(1.0, 1.0 - (Double(remainingSeconds) / total)))
            } else {
                progress = 0.0
            }

            // Calculate ETA only if significant time remains
            if remainingSeconds > 60 {
                let date = Date().addingTimeInterval(TimeInterval(remainingSeconds))
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                nextBreakText = "Break at \(formatter.string(from: date))"
            } else {
                nextBreakText = "Break soon"
            }
        } else if currentState == .idle {
            progress = 0.0
            nextBreakText = nil
        }
    }

    private func updateStrain() {
        if currentState == .work {
            // Increase strain
            strainLevel = min(1.0, strainLevel + 0.05)
        } else if currentState == .break {
            // Recover
            strainLevel = max(0.0, strainLevel - 0.2)
        }
    }

    private var strainDescription: String {
        if strainLevel < 0.3 { return "Low" }
        if strainLevel < 0.7 { return "Medium" }
        return "High"
    }

    // MARK: - Actions (Passthrough)

    public func toggleTimer() {
        stateMachine.toggle()
    }

    public func skipBreak() {
        // Game theory: Penalty for skipping
        strainLevel = min(1.0, strainLevel + 0.15)
        stateMachine.skipToNext()
    }

    public func triggerShortBreak() {
        // Pause the timer while taking manual break to prevent desync
        // The timer will resume when the break overlay is dismissed
        if stateMachine.currentState == .work && !stateMachine.isPaused {
            stateMachine.pause(source: .user)
        }

        Renderer.showBreak(durationSeconds: 20)
        // Reset strain slightly for manual break
        strainLevel = max(0.0, strainLevel - 0.1)
    }

    /// Trigger a long break (5 minutes)
    public func triggerLongBreak() {
        // Pause the timer while taking manual break to prevent desync
        if stateMachine.currentState == .work && !stateMachine.isPaused {
            stateMachine.pause(source: .user)
        }

        let longBreakDuration = PreferencesManager.shared.longBreakDurationSeconds
        Renderer.showBreak(durationSeconds: longBreakDuration)
        // More strain relief for long break
        strainLevel = max(0.0, strainLevel - 0.3)
        // Play special sound
        SoundManager.shared.playFocusEnd()
    }

    /// Postpone the next break by 5 minutes
    public func postponeBreak() {
        stateMachine.postpone(minutes: 5)
        // Small penalty for postponing
        strainLevel = min(1.0, strainLevel + 0.05)
    }

    public func triggerPostureNudge() {
        Renderer.showNudge(type: .posture)
    }

    public func triggerBlinkNudge() {
        Renderer.showNudge(type: .blink)
    }

    public func resetSession() {
        stateMachine.reset()
        strainLevel = 0.0
    }

    // MARK: - Timer Mode

    public var currentTimerMode: TimerConfiguration.TimerMode {
        stateMachine.configuration.mode
    }

    public func setTimerMode(_ mode: TimerConfiguration.TimerMode) {
        switch mode {
        case .eyeCare:
            stateMachine.configuration = .default
        case .custom:
            break  // Custom mode handled elsewhere
        }

        // Reset to apply new configuration
        if stateMachine.currentState != .idle {
            stateMachine.reset()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }

    private func formatTimeCompact(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
