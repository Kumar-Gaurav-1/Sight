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

    // MARK: - NSApplicationDelegate

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application launched")

        // Configure state machine with saved preferences
        stateMachine.configuration = PreferencesManager.shared.timerConfiguration

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
                    self.logger.info(
                        "Smart Pause: pausing for \(SmartPauseManager.shared.activeSignals.first?.description ?? "unknown")"
                    )
                    self.stateMachine.pause(source: .smartPause)
                } else if !shouldPause && self.stateMachine.isPaused
                    && self.stateMachine.pauseSource == .smartPause
                {
                    // Only auto-resume if WE (SmartPause) were the one who paused it
                    self.logger.info("Smart Pause: signals cleared, resuming")
                    self.stateMachine.resume()
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

        // Hide dock icon (LSUIElement behavior)
        NSApp.setActivationPolicy(.accessory)

        logger.info("Menu bar initialized")

        // Check Onboarding
        if !PreferencesManager.shared.hasCompletedOnboarding {
            showOnboarding()
        }

        // Auto-start the timer (only if not in quiet hours)
        if !WorkHoursManager.shared.shouldPause() {
            stateMachine.start()
            logger.info("Timer started automatically")
        } else {
            logger.info("Timer not started: \(WorkHoursManager.shared.pauseReason ?? "schedule")")
        }
    }

    private func showOnboarding() {
        let onboardingView = SightOnboardingView()
        let hostingController = NSHostingController(rootView: onboardingView)

        onboardingWindow = NSWindow(contentViewController: hostingController)
        onboardingWindow?.title = "Welcome to Sight"
        onboardingWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
        onboardingWindow?.titlebarAppearsTransparent = true
        onboardingWindow?.isMovableByWindowBackground = true
        onboardingWindow?.setContentSize(NSSize(width: 550, height: 450))
        onboardingWindow?.center()
        onboardingWindow?.isReleasedWhenClosed = false
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application terminating")
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
}
