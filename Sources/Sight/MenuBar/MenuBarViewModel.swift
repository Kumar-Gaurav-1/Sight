import AppKit
import Combine
import Foundation

@MainActor
public final class MenuBarViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var currentState: TimerState = .idle
    @Published public private(set) var remainingSeconds: Int = 0
    @Published public private(set) var strainLevel: Float = 0.0 {  // 0.0 to 1.0, persisted
        didSet {
            // Persist strain level across app restarts
            UserDefaults.standard.set(Double(strainLevel), forKey: "sightStrainLevel")
        }
    }

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
    private var breakEndedObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init(stateMachine: TimerStateMachine) {
        self.stateMachine = stateMachine

        // Restore persisted strain level
        self.strainLevel = Float(UserDefaults.standard.double(forKey: "sightStrainLevel"))

        setupBindings()
        setupNotificationObservers()

        // Initial state
        self.currentState = stateMachine.currentState
        self.remainingSeconds = stateMachine.remainingSeconds
        updateDerivedProperties()
    }

    deinit {
        if let observer = breakEndedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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

    /// Setup notification observers for break events
    private func setupNotificationObservers() {
        // Now handled entirely by StateMachine natively. Keeping empty implementation
        // temporarily if other parts are still transitioning or observing.
        breakEndedObserver = nil
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

            // Calculate preBreak progress (ring drains during countdown)
            let preBreakTotal = Double(stateMachine.configuration.preBreakSeconds)
            if preBreakTotal > 0 {
                progress = max(0.0, min(1.0, Double(remainingSeconds) / preBreakTotal))
            } else {
                progress = 0.0
            }
            nextBreakText = nil

        case .break:
            statusIconName = "cup.and.saucer"
            statusLabel = "Break"
            hudTitle = "On Break"
            hudDetail = "Relax those eyes..."
            // Calculate break progress (ring drains as break completes)
            let breakDuration = Double(stateMachine.configuration.breakDurationSeconds)
            if breakDuration > 0 {
                progress = max(0.0, min(1.0, Double(remainingSeconds) / breakDuration))
            } else {
                progress = 0.0
            }
            nextBreakText = nil
        }

        // Calculate Progress (Work) - ring fills as work progresses
        if currentState == .work {
            let total = Double(stateMachine.configuration.workIntervalSeconds)
            // Progress increases as time passes (ring fills up)
            if total > 0 {
                progress = max(0.0, min(1.0, 1.0 - (Double(remainingSeconds) / total)))
            } else {
                progress = 0.0
            }

            // Calculate ETA with granular countdown
            if remainingSeconds > 120 {
                let date = Date().addingTimeInterval(TimeInterval(remainingSeconds))
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                nextBreakText = "Break at \(formatter.string(from: date))"
            } else if remainingSeconds > 30 {
                let mins = remainingSeconds / 60
                let secs = remainingSeconds % 60
                if mins > 0 {
                    nextBreakText = "Break in \(mins)m \(secs)s"
                } else {
                    nextBreakText = "Break in \(secs)s"
                }
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

    /// Human-readable strain level description
    public var strainDescription: String {
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
        stateMachine.startManualBreak(forceLong: false)
        // Reset strain slightly for manual break
        strainLevel = max(0.0, strainLevel - 0.1)
    }

    /// Trigger a long break (5 minutes)
    public func triggerLongBreak() {
        stateMachine.startManualBreak(forceLong: true)
        // More strain relief for long break
        strainLevel = max(0.0, strainLevel - 0.3)
        // Note: Sound is played by StateMachine on transition
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
