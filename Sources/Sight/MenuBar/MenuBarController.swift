import AppKit
import Combine
import SwiftUI
import os.log

/// Controls the menu bar status item and its menu
@MainActor
public final class MenuBarController: NSObject, NSMenuDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    let viewModel: MenuBarViewModel
    private var cancellables = Set<AnyCancellable>()
    private var currentMenu: NSMenu?
    private var hostingController: NSHostingController<SightMenuBarView>?
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.app", category: "MenuBar")

    // Animation state
    private var iconAnimationTimer: Timer?
    private var isAnimatingIcon = false

    // MARK: - Initialization

    public init(stateMachine: TimerStateMachine) {
        self.viewModel = MenuBarViewModel(stateMachine: stateMachine)
        super.init()
        setupStatusItem()
        observeViewModel()
    }

    deinit {
        iconAnimationTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            logger.error("Failed to create status bar button")
            return
        }

        // Style the button
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)

        // Initial setup
        updateStatusItemUI()

        // Interaction
        button.action = #selector(statusBarButtonClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        logger.info("Status bar item created")
    }

    private func observeViewModel() {
        // Combined observer for icon and label
        Publishers.CombineLatest(
            viewModel.$statusIconName,
            viewModel.$statusLabel
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _ in
            self?.updateStatusItemUI()
        }
        .store(in: &cancellables)

        // Observe state changes for icon animation
        viewModel.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)

        // Observe menu bar preference changes
        let prefs = PreferencesManager.shared
        prefs.$showInMenuBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.statusItem?.isVisible = show
            }
            .store(in: &cancellables)

        prefs.$showTimerInMenuBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemUI()
            }
            .store(in: &cancellables)
    }

    // MARK: - Icon Animation

    private func handleStateChange(_ state: TimerState) {
        switch state {
        case .preBreak:
            // Pulse icon to draw attention
            startIconPulse()
        case .break:
            // Show break icon animation
            stopIconPulse()
        default:
            stopIconPulse()
        }
    }

    private func startIconPulse() {
        guard !isAnimatingIcon else { return }
        isAnimatingIcon = true

        var toggle = false
        iconAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
            [weak self] _ in
            // Dispatch to MainActor for thread safety
            Task { @MainActor in
                guard let self = self, let button = self.statusItem?.button else { return }

                // Alternate between filled and empty icon
                let iconName = toggle ? "bell.fill" : "bell"
                if let image = NSImage(
                    systemSymbolName: iconName, accessibilityDescription: "Break Soon")
                {
                    image.isTemplate = true
                    button.image = image
                }
                toggle.toggle()
            }
        }
    }

    private func stopIconPulse() {
        iconAnimationTimer?.invalidate()
        iconAnimationTimer = nil
        isAnimatingIcon = false
    }

    // MARK: - UI Update

    private var lastTitle: String?
    private var lastIconName: String?

    private func updateStatusItemUI() {
        guard let button = statusItem?.button else { return }

        let newIconName = viewModel.statusIconName

        // Only show timer if preference is enabled
        let showTimer = PreferencesManager.shared.showTimerInMenuBar
        let newTitle = showTimer ? (viewModel.statusLabel ?? "") : ""

        let pauseHint = viewModel.isPaused ? " (⌥+click to resume)" : " (⌥+click to pause)"
        let newTooltip = "\(viewModel.hudTitle) - \(viewModel.hudDetail)\(pauseHint)"

        // Update icon if changed
        if newIconName != lastIconName && !isAnimatingIcon {
            if let image = NSImage(
                systemSymbolName: newIconName, accessibilityDescription: viewModel.hudTitle)
            {
                image.isTemplate = true
                // Add slight padding
                image.size = NSSize(width: 16, height: 16)
                button.image = image
            }
            lastIconName = newIconName
        }

        // Update title if changed (respects showTimerInMenuBar)
        if newTitle != lastTitle {
            if newTitle.isEmpty {
                button.title = ""
            } else {
                // Add spacing between icon and text
                button.title = " \(newTitle)"
            }
            lastTitle = newTitle
        }

        // Update tooltip
        if button.toolTip != newTooltip {
            button.toolTip = newTooltip
        }
    }

    // MARK: - Actions

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        // Option+Click = Quick toggle
        // Regular click = Show dashboard
        if event.modifierFlags.contains(.option) {
            viewModel.toggleTimer()

            // Visual feedback - briefly highlight
            if let button = statusItem?.button {
                button.highlight(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    button.highlight(false)
                }
            }
        } else {
            showMenu()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.delegate = self

        // Premium dashboard view with dynamic sizing
        let dashboardView = SightMenuBarView(viewModel: viewModel)
        let controller = NSHostingController(rootView: dashboardView)

        // Let SwiftUI determine the natural size
        let fittingSize = controller.view.fittingSize
        controller.view.frame = NSRect(x: 0, y: 0, width: 280, height: fittingSize.height)
        controller.view.wantsLayer = true
        controller.view.layer?.cornerRadius = 10

        let customItem = NSMenuItem()
        customItem.view = controller.view
        menu.addItem(customItem)

        // Store references
        self.hostingController = controller
        self.currentMenu = menu

        // Show menu
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
    }

    // MARK: - NSMenuDelegate

    public func menuDidClose(_ menu: NSMenu) {
        // Cleanup with slight delay to ensure system is done
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem?.menu = nil
            self?.currentMenu = nil
            self?.hostingController = nil
        }
    }

    // MARK: - Public Actions

    @objc private func menuToggle() { viewModel.toggleTimer() }
    @objc private func menuSkip() { viewModel.skipBreak() }
    @objc private func menuQuickBreak() { viewModel.triggerShortBreak() }
    @objc private func menuReset() { viewModel.resetSession() }

    @objc private func menuPreferences() {
        NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }
}
