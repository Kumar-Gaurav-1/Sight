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

    private let logger = Logger(subsystem: "com.kumargaurav.Sight.app", category: "Shortcuts")
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
        // Check if shortcuts are enabled
        guard PreferencesManager.shared.shortcutsEnabled else { return false }

        let prefs = PreferencesManager.shared

        // Check each configurable shortcut
        if matchesShortcut(event, prefs.shortcutToggleTimer) {
            logger.info("Shortcut triggered: Toggle Timer")
            DispatchQueue.main.async {
                self.menuBarViewModel?.toggleTimer()
            }
            return true
        }

        if matchesShortcut(event, prefs.shortcutTakeBreak) {
            logger.info("Shortcut triggered: Take Break")
            DispatchQueue.main.async {
                self.menuBarViewModel?.triggerShortBreak()
            }
            return true
        }

        if matchesShortcut(event, prefs.shortcutSkipBreak) {
            logger.info("Shortcut triggered: Skip Break")
            DispatchQueue.main.async {
                self.menuBarViewModel?.skipBreak()
            }
            return true
        }

        if matchesShortcut(event, prefs.shortcutPreferences) {
            logger.info("Shortcut triggered: Open Preferences")
            DispatchQueue.main.async {
                self.openPreferences?()
            }
            return true
        }

        return false
    }

    /// Check if event matches a shortcut string (format: "cmd+ctrl:keyCode")
    private func matchesShortcut(_ event: NSEvent, _ shortcut: String) -> Bool {
        let parts = shortcut.split(separator: ":")
        guard parts.count == 2,
            let keyCode = UInt16(parts[1])
        else { return false }

        let modifierString = String(parts[0])
        var expectedModifiers: NSEvent.ModifierFlags = []

        if modifierString.contains("cmd") { expectedModifiers.insert(.command) }
        if modifierString.contains("ctrl") { expectedModifiers.insert(.control) }
        if modifierString.contains("opt") { expectedModifiers.insert(.option) }
        if modifierString.contains("shift") { expectedModifiers.insert(.shift) }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags == expectedModifiers && event.keyCode == keyCode
    }

    /// Convert shortcut string to display format
    public static func displayString(for shortcut: String) -> String {
        let parts = shortcut.split(separator: ":")
        guard parts.count == 2,
            let keyCode = UInt16(parts[1])
        else { return "Not Set" }

        let modifierString = String(parts[0])
        var symbols = ""

        if modifierString.contains("ctrl") { symbols += "⌃" }
        if modifierString.contains("opt") { symbols += "⌥" }
        if modifierString.contains("shift") { symbols += "⇧" }
        if modifierString.contains("cmd") { symbols += "⌘" }

        let keyChar = keyCodeToChar(keyCode)
        return symbols + keyChar
    }

    /// Convert keyCode to character
    private static func keyCodeToChar(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "␣", 50: "`",
            51: "⌫", 53: "⎋", 96: "F5", 97: "F6", 98: "F7", 99: "F3",
            100: "F8", 101: "F9", 103: "F11", 105: "F13", 107: "F14",
            109: "F10", 111: "F12", 113: "F15", 118: "F4", 120: "F2",
            122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return keyMap[keyCode] ?? "?"
    }

    // MARK: - Callbacks

    /// Callback to open preferences window (set by AppDelegate)
    public var openPreferences: (() -> Void)?
}
