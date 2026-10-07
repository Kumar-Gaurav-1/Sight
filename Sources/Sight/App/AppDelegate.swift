import AppKit
import Combine
import SwiftUI
import os.log

/// Application delegate for menu bar app lifecycle
@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var menuBarController: MenuBarController?
    private var preferencesWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private let stateMachine = TimerStateMachine()
    private let logger = Logger(subsystem: "com.sight.app", category: "AppDelegate")
    private var cancellables = Set<AnyCancellable>()

    // SECURITY: Debounce for skip notifications to prevent double-processing
    private var lastSkipTime: Date?

    // PERFORMANCE: Memory pressure monitoring for 24/7 operation
    private var memoryPressureSource: DispatchSourceMemoryPressure?

    // PERFORMANCE: Prevent App Nap to ensure timer accuracy
    private var timerActivity: NSObjectProtocol?

    // MARK: - NSApplicationDelegate

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application launched")

        // Configure state machine with saved preferences
        stateMachine.configuration = PreferencesManager.shared.timerConfiguration

        // Set shared instance for global access (skip difficulty, etc.)
        TimerStateMachine.shared = stateMachine

        // Initialize menu bar controller
        menuBarController = MenuBarController(stateMachine: stateMachine)

        // Configure shortcuts
        if let vm = menuBarController?.viewModel {
            ShortcutManager.shared.configure(with: vm)
            ShortcutManager.shared.openPreferences = { [weak self] in
                self?.openPreferences()
            }
            ShortcutManager.shared.startMonitoring()
        }

        // Setup Nudges
        MicroNudgesManager.shared.onNudge = { event in
            Renderer.showNudge(type: event.type)
        }
        MicroNudgesManager.shared.start()

        // Request notification permissions
        NotificationManager.shared.requestAuthorization()

        // Setup Idle Detection
        IdleDetector.shared.onIdlePause = { [weak self] in
            self?.stateMachine.pause(source: .idle)
        }
        IdleDetector.shared.onIdleResume = { [weak self] in
            // Only resume if we (IdleDetector) were the one who paused it
            if self?.stateMachine.pauseSource == .idle {
                self?.stateMachine.resume()
                SoundManager.shared.playIdleResume()  // Play sound when returning from idle
            }
        }
        IdleDetector.shared.onIdleReset = { [weak self] in
            self?.stateMachine.reset()
        }
        IdleDetector.shared.start()

        // Setup Smart Pause (screen recording, meetings, fullscreen detection)
        SmartPauseManager.shared.startMonitoring()
        SmartPauseManager.shared.$shouldPause
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldPause in
                guard let self = self else { return }
                if shouldPause && self.stateMachine.currentState != .idle
                    && !self.stateMachine.isPaused
                {
                    let reason =
                        SmartPauseManager.shared.activeSignals.first?.description
                        ?? "activity detected"
                    self.logger.info(
                        "Smart Pause: pausing for \(reason)"
                    )
                    self.stateMachine.pause(source: .smartPause)
                    SoundManager.shared.playSmartPause()  // Play sound on smart pause
                    NotificationManager.shared.sendSmartPauseStartNotification(reason: reason)
                } else if !shouldPause && self.stateMachine.isPaused
                    && self.stateMachine.pauseSource == .smartPause
                {
                    // Only auto-resume if WE (SmartPause) were the one who paused it
                    self.logger.info("Smart Pause: signals cleared, resuming")
                    self.stateMachine.resume()
                    SoundManager.shared.playSmartPause()  // Play sound on resume too
                    NotificationManager.shared.sendSmartPauseEndNotification()
                }
            }
            .store(in: &cancellables)

        // Sync Launch at Login with system
        LoginItemManager.shared.syncWithPreferences(PreferencesManager.shared)

        // Observe launchAtLogin preference changes
        PreferencesManager.shared.$launchAtLogin
            .receive(on: DispatchQueue.main)
            .sink { enabled in
                LoginItemManager.shared.setEnabled(enabled)
            }
            .store(in: &cancellables)

        // Observe skip break events from overlay (Escape key, Skip button)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SightSkipBreak"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // SECURITY: Debounce to prevent double-skip
                // If skipToNext was called recently (within 500ms), ignore this notification
                let now = Date()
                if let lastSkip = self.lastSkipTime, now.timeIntervalSince(lastSkip) < 0.5 {
                    self.logger.debug("Ignoring duplicate SightSkipBreak notification")
                    return
                }
                self.lastSkipTime = now

                // Only skip if we're actually in break state
                // This prevents transitioning from work->preBreak if notification arrives late
                guard self.stateMachine.currentState == .break else {
                    self.logger.debug("SightSkipBreak ignored - not in break state")
                    return
                }

                self.logger.info("Break skipped via overlay")
                self.stateMachine.skipToNext()
            }
        }

        // Observe break ended events (for manual breaks to resume timer)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SightBreakEnded"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Resume timer if it was paused by user (manual break)
                if self.stateMachine.isPaused && self.stateMachine.pauseSource == .user {
                    self.logger.info("Manual break ended, resuming timer")
                    self.stateMachine.resume()
                }
            }
        }

        // Observe take break requests (from Statistics view or other UI)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SightTakeBreak"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                self.logger.info("Take break requested via notification")
                self.menuBarController?.viewModel.triggerShortBreak()
            }
        }

        // Observe postpone break requests (5 min later from notification)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SightPostponeBreak"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            Task { @MainActor in
                let minutes = (notification.userInfo?["minutes"] as? Int) ?? 5
                self.logger.info("Break postponed for \(minutes) minutes via notification")
                // Postpone the break by adding time to the work interval
                self.stateMachine.postpone(minutes: minutes)
            }
        }

        // Hide dock icon (LSUIElement behavior)
        NSApp.setActivationPolicy(.accessory)

        logger.info("Menu bar initialized")

        // Check Onboarding
        if !PreferencesManager.shared.hasCompletedOnboarding {
            showOnboarding()
            // Timer will start after onboarding completes via notification
            setupOnboardingCompletionListener()
        } else {
            // Onboarding already done - start timer normally
            startTimerIfAppropriate()
        }

        // PERFORMANCE: Setup monitoring for 24/7 operation
        setupMemoryPressureMonitoring()
        setupAppNapPrevention()
    }

    private func startTimerIfAppropriate() {
        // Initialize managers
        _ = PreferencesManager.shared

        // Only start if not in quiet hours
        if !WorkHoursManager.shared.shouldPause() {
            stateMachine.start()
            logger.info("Timer started automatically")
        } else {
            logger.info("Timer not started: \(WorkHoursManager.shared.pauseReason ?? "schedule")")
        }
    }

    private func setupOnboardingCompletionListener() {
        // Listen for onboarding completion notification
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OnboardingCompleted"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("Onboarding completed - starting timer")
            Task { @MainActor in
                self.startTimerIfAppropriate()
            }
        }
    }

    private func showOnboarding() {
        logger.info("Showing onboarding window...")

        // Small delay to ensure app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            let onboardingView = OnboardingView()
            let hostingController = NSHostingController(rootView: onboardingView)

            self.onboardingWindow = NSWindow(contentViewController: hostingController)
            self.onboardingWindow?.identifier = NSUserInterfaceItemIdentifier("onboarding")
            self.onboardingWindow?.title = "Welcome to Sight"
            self.onboardingWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
            self.onboardingWindow?.titlebarAppearsTransparent = true
            self.onboardingWindow?.isMovableByWindowBackground = true
            self.onboardingWindow?.setContentSize(NSSize(width: 650, height: 600))
            self.onboardingWindow?.center()
            self.onboardingWindow?.isReleasedWhenClosed = false
            self.onboardingWindow?.level = .floating  // Ensure window appears above others
            self.onboardingWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.logger.info("Onboarding window displayed: \(self.onboardingWindow != nil)")
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application terminating - cleaning up")

        // End any active statistics session
        StatisticsEngine.shared.endSession()

        // Save current stats
        logger.info("Goodbye!")
    }

    // MARK: - Actions

    @objc public func openPreferences() {
        if preferencesWindow == nil {
            let preferencesView = SightPreferencesView()
            let hostingController = NSHostingController(rootView: preferencesView)

            preferencesWindow = NSWindow(contentViewController: hostingController)
            preferencesWindow?.title = "Sight Preferences"
            preferencesWindow?.styleMask = [.titled, .closable, .resizable]
            preferencesWindow?.setContentSize(NSSize(width: 900, height: 650))
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Performance Monitoring

    /// Setup memory pressure monitoring for long-running 24/7 operation
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main
        )

        memoryPressureSource?.setEventHandler { [weak self] in
            guard let self = self,
                let event = self.memoryPressureSource?.data
            else { return }

            if event.contains(.warning) {
                self.logger.warning("Memory pressure warning - cleaning up")
            }

            if event.contains(.critical) {
                self.logger.critical("Memory pressure critical")
                if BreakOverlayManager.shared.isShowing {
                    BreakOverlayManager.shared.hide()
                }
            }
        }

        memoryPressureSource?.resume()
        logger.info("Memory pressure monitoring enabled")
    }

    /// Prevent App Nap to ensure timer runs accurately when backgrounded
    private func setupAppNapPrevention() {
        timerActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Break timer must run accurately"
        )
        logger.info("App Nap prevention enabled")
    }
}
