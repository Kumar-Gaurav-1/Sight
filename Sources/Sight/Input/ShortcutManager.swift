import AppKit
import Carbon
import Combine
import os.log

/// Manages global keyboard shortcuts
/// Uses NSEvent.addGlobalMonitorForEvents (Passive)
/// Note: This requires Accessibility permissions to receive events from other apps
public final class ShortcutManager: ObservableObject {

    public static let shared = ShortcutManager()

    @Published public var isMonitoring = false
    @Published public var hasAccessibilityAccess = false

    private let logger = Logger(subsystem: "com.sight.app", category: "Shortcuts")
    private var monitor: Any?
    private var localMonitor: Any?

    // SECURITY: Store permission timer for cleanup
    private var permissionTimer: Timer?

    // Dependencies
    private var menuBarViewModel: MenuBarViewModel?

    init() {
        checkPermissions()
    }

    public func configure(with viewModel: MenuBarViewModel) {
        self.menuBarViewModel = viewModel
    }

    public func startMonitoring() {
        guard monitor == nil else { return }

        // Check permissions first
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ]
        hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)

        // SECURITY: Only set up global monitor if we have accessibility permission
        // Global monitoring requires accessibility access and will silently fail without it
        if hasAccessibilityAccess {
            // Passive global monitor (for when other apps are focused)
            monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleEvent(event)
            }
            logger.info("Global shortcut monitor started (accessibility granted)")
        } else {
            logger.warning(
                "Accessibility access missing - global shortcuts disabled, only local shortcuts active"
            )
        }

        // Local monitor always works (for when Sight windows are focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleEvent(event) == true {
                return nil  // Consume the event
            }
            return event
        }

        isMonitoring = true
    }

    public func stopMonitoring() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        isMonitoring = false
    }

    public func checkPermissions() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ]
        hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)
    }

    public func requestPermissions() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        _ = AXIsProcessTrustedWithOptions(options)

        // SECURITY: Store timer reference to allow cleanup, with 60-second timeout
        var permissionCheckCount = 0
        let maxChecks = 60  // 60 seconds timeout

        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] timer in
            permissionCheckCount += 1
            self?.checkPermissions()

            if self?.hasAccessibilityAccess == true {
                timer.invalidate()
                self?.permissionTimer = nil
                self?.restartMonitoring()
                self?.logger.info("Accessibility granted - restarted monitoring")
            } else if permissionCheckCount >= maxChecks {
                timer.invalidate()
                self?.permissionTimer = nil
                self?.logger.warning("Accessibility permission timeout after 60 seconds")
            }
        }
    }

    /// Restart monitoring after permission changes
    public func restartMonitoring() {
        stopMonitoring()
        startMonitoring()
    }

    @discardableResult
    private func handleEvent(_ event: NSEvent) -> Bool {
        // Defined shortcuts:
        // Cmd + Ctrl + P = Toggle Pause/Resume
        // Cmd + Ctrl + B = Take Break Now
        // Cmd + Ctrl + S = Skip Break
        // Cmd + Ctrl + , = Open Preferences

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Cmd + Ctrl
        if flags == [.command, .control] {
            switch event.keyCode {
            case 35:  // 'P'
                logger.info("Shortcut triggered: Toggle Timer")
                DispatchQueue.main.async {
                    self.menuBarViewModel?.toggleTimer()
                }
                return true

            case 11:  // 'B'
                logger.info("Shortcut triggered: Take Break")
                DispatchQueue.main.async {
                    // Use viewModel to properly pause timer before showing break
                    self.menuBarViewModel?.triggerShortBreak()
                }
                return true

            case 1:  // 'S'
                logger.info("Shortcut triggered: Skip Break")
                DispatchQueue.main.async {
                    self.menuBarViewModel?.skipBreak()
                }
                return true

            case 43:  // ','
                logger.info("Shortcut triggered: Open Preferences")
                DispatchQueue.main.async {
                    self.openPreferences?()
                }
                return true

            default:
                break
            }
        }
        return false
    }

    // MARK: - Callbacks

    /// Callback to open preferences window (set by AppDelegate)
    public var openPreferences: (() -> Void)?
}
