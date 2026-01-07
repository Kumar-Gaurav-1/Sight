import AppKit
import Foundation
import UserNotifications
import os.log

/// Manages system notifications for break reminders
/// Handles gracefully when running without proper app bundle (e.g., SPM executable)
public final class NotificationManager: NSObject, ObservableObject {

    public static let shared = NotificationManager()

    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var isAvailable: Bool = false

    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "Notifications")
    private var center: UNUserNotificationCenter?

    // MARK: - Notification Categories

    private enum Category {
        static let breakReminder = "BREAK_REMINDER"
        static let preBreak = "PRE_BREAK"
        static let wellness = "WELLNESS"
        static let escalation = "ESCALATION"
        static let smartPause = "SMART_PAUSE"
    }

    private enum Action {
        static let startBreak = "START_BREAK"
        static let skip = "SKIP"
        static let postpone = "POSTPONE"
        static let snooze = "SNOOZE"
        static let dismiss = "DISMISS"
        static let takeBreakNow = "TAKE_BREAK_NOW"
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupNotificationCenter()
    }

    private func setupNotificationCenter() {
        // Check if we have a proper bundle identifier (required for notifications)
        guard Bundle.main.bundleIdentifier != nil else {
            logger.warning("No bundle identifier - notifications unavailable (SPM executable?)")
            isAvailable = false
            return
        }

        // Initialize the notification center
        let notificationCenter = UNUserNotificationCenter.current()
        self.center = notificationCenter
        notificationCenter.delegate = self
        isAvailable = true
        setupCategories()
        checkAuthorizationStatus()
        logger.info("Notification center initialized")
    }

    // MARK: - Authorization

    /// Request notification permission
    public func requestAuthorization() {
        guard let center = center else {
            logger.warning("Notifications not available")
            return
        }

        center.requestAuthorization(options: [.alert, .sound, .badge]) {
            [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }

            if let error = error {
                self?.logger.error(
                    "Notification authorization error: \(error.localizedDescription)")
            } else if granted {
                self?.logger.info("Notifications authorized")
            }
        }
    }

    private func checkAuthorizationStatus() {
        guard let center = center else { return }

        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Categories

    private func setupCategories() {
        guard let center = center else { return }

        // Break reminder actions
        let startAction = UNNotificationAction(
            identifier: Action.startBreak,
            title: "Start Break",
            options: .foreground
        )

        let skipAction = UNNotificationAction(
            identifier: Action.skip,
            title: "Skip",
            options: .destructive
        )

        let postponeAction = UNNotificationAction(
            identifier: Action.postpone,
            title: "5 min later",
            options: []
        )

        // Wellness actions
        let snoozeAction = UNNotificationAction(
            identifier: Action.snooze,
            title: "Snooze 5 min",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: Action.dismiss,
            title: "Dismiss",
            options: .destructive
        )

        // Escalation actions
        let takeBreakNowAction = UNNotificationAction(
            identifier: Action.takeBreakNow,
            title: "Take Break Now",
            options: .foreground
        )

        // Break reminder category
        let breakCategory = UNNotificationCategory(
            identifier: Category.breakReminder,
            actions: [startAction, skipAction, postponeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Pre-break countdown category
        let preBreakCategory = UNNotificationCategory(
            identifier: Category.preBreak,
            actions: [startAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        // Wellness reminder category (posture/blink)
        let wellnessCategory = UNNotificationCategory(
            identifier: Category.wellness,
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Escalation category (after multiple snoozes)
        let escalationCategory = UNNotificationCategory(
            identifier: Category.escalation,
            actions: [takeBreakNowAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Smart pause category (meeting/screen recording paused)
        let smartPauseCategory = UNNotificationCategory(
            identifier: Category.smartPause,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            breakCategory,
            preBreakCategory,
            wellnessCategory,
            escalationCategory,
            smartPauseCategory,
        ])
    }

    // MARK: - Thread Identifier (for grouping)

    private let threadIdentifier = "com.sight.breaks"

    // MARK: - Helper Methods

    /// Get sound based on user preference
    private func notificationSound() -> UNNotificationSound? {
        guard PreferencesManager.shared.breakReminderSoundEnabled else { return nil }
        return .default
    }

    /// Format duration for user display
    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        return "\(seconds) seconds"
    }

    // MARK: - Send Notifications

    /// Send a pre-break warning notification
    public func sendPreBreakNotification(secondsRemaining: Int) {
        guard let center = center, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Break Coming Up"
        content.body = "Take a break in \(formatDuration(secondsRemaining))"
        content.sound = notificationSound()
        content.categoryIdentifier = Category.preBreak
        content.threadIdentifier = threadIdentifier

        let request = UNNotificationRequest(
            identifier: "preBreak",
            content: content,
            trigger: nil  // Immediate
        )

        // Clear previous pre-break notification
        center.removePendingNotificationRequests(withIdentifiers: ["preBreak"])
        center.removeDeliveredNotifications(withIdentifiers: ["preBreak"])

        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error(
                    "Failed to send pre-break notification: \(error.localizedDescription)")
            }
        }
    }

    /// Send a break start notification
    public func sendBreakStartNotification(durationSeconds: Int) {
        guard let center = center, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time for a Break! 👁"
        content.body = "Look away from the screen for \(formatDuration(durationSeconds))"
        content.sound = notificationSound()
        content.categoryIdentifier = Category.breakReminder
        content.threadIdentifier = threadIdentifier

        let request = UNNotificationRequest(
            identifier: "breakStart",
            content: content,
            trigger: nil
        )

        // Clear previous break notification
        center.removePendingNotificationRequests(withIdentifiers: ["breakStart"])
        center.removeDeliveredNotifications(withIdentifiers: ["breakStart"])

        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error(
                    "Failed to send break notification: \(error.localizedDescription)")
            }
        }
    }

    /// Send a break end notification
    public func sendBreakEndNotification() {
        guard let center = center, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Break Complete ✓"
        content.body = "Great job! Ready to get back to work?"
        content.sound = notificationSound()
        content.categoryIdentifier = Category.breakReminder  // Enable action buttons
        content.threadIdentifier = threadIdentifier

        let request = UNNotificationRequest(
            identifier: "breakEnd",
            content: content,
            trigger: nil
        )

        // Clear previous and add new
        center.removeDeliveredNotifications(withIdentifiers: ["breakEnd"])

        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error(
                    "Failed to send break end notification: \(error.localizedDescription)")
            }
        }
    }

    /// Send an overtime notification when user works past break interval
    public func sendOvertimeNotification(minutesPast: Int) {
        guard let center = center, isAuthorized else { return }
        guard PreferencesManager.shared.overtimeNudgeSoundEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "You've Been Working a While ⏰"
        content.body = "You're \(minutesPast) minutes past your break. Time for a rest?"
        content.sound = notificationSound()
        content.categoryIdentifier = Category.breakReminder
        content.threadIdentifier = threadIdentifier

        let request = UNNotificationRequest(
            identifier: "overtime",
            content: content,
            trigger: nil
        )

        center.removeDeliveredNotifications(withIdentifiers: ["overtime"])

        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error(
                    "Failed to send overtime notification: \(error.localizedDescription)")
            }
        }
    }

    /// Send a wellness reminder notification (posture/blink)
    public func sendWellnessNotification(type: String, message: String) {
        guard let center = center, isAuthorized else { return }

        // Check if wellness reminders are enabled (not sound - actual reminder toggle)
        let isEnabled =
            type == "posture"
            ? PreferencesManager.shared.postureReminderEnabled
            : PreferencesManager.shared.blinkReminderEnabled
        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = type == "posture" ? "Posture Check 🧘" : "Blink Reminder 👁"
        content.body = message
        // Use wellness-specific sound preference
        let soundEnabled =
            type == "posture"
            ? PreferencesManager.shared.postureSoundEnabled
            : PreferencesManager.shared.blinkSoundEnabled
        content.sound = soundEnabled ? .default : nil
        content.categoryIdentifier = Category.wellness
        content.threadIdentifier = "com.sight.wellness"

        let request = UNNotificationRequest(
            identifier: "wellness-\(type)",
            content: content,
            trigger: nil
        )

        center.removeDeliveredNotifications(withIdentifiers: ["wellness-\(type)"])

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error(
                        "Failed to send wellness notification: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Smart Pause Notifications

    /// Send notification when smart pause starts (meeting, screen recording, etc.)
    public func sendSmartPauseStartNotification(reason: String) {
        guard let center = center, isAuthorized else { return }
        guard PreferencesManager.shared.smartPauseNotificationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Breaks Paused ⏸"
        content.body = "Automatically paused: \(reason)"
        content.sound = nil  // Silent notification
        content.categoryIdentifier = Category.smartPause
        content.threadIdentifier = "com.sight.smartpause"

        let request = UNNotificationRequest(
            identifier: "smartpause-start",
            content: content,
            trigger: nil
        )

        center.removeDeliveredNotifications(withIdentifiers: ["smartpause-start", "smartpause-end"])

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error(
                        "Failed to send smart pause start notification: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    /// Send notification when smart pause ends
    public func sendSmartPauseEndNotification() {
        guard let center = center, isAuthorized else { return }
        guard PreferencesManager.shared.smartPauseNotificationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Breaks Resumed ▶"
        content.body = "Break reminders are active again"
        content.sound = nil  // Silent notification
        content.categoryIdentifier = Category.smartPause
        content.threadIdentifier = "com.sight.smartpause"

        let request = UNNotificationRequest(
            identifier: "smartpause-end",
            content: content,
            trigger: nil
        )

        center.removeDeliveredNotifications(withIdentifiers: ["smartpause-start", "smartpause-end"])

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error(
                        "Failed to send smart pause end notification: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Escalation Notifications

    /// Send escalation notification after multiple snoozes
    public func sendEscalationNotification(snoozeCount: Int) {
        guard let center = center, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time for a Real Break 🛑"
        content.body =
            "You've snoozed \(snoozeCount) times. A short break now prevents a longer recovery later."
        content.sound = .default
        content.categoryIdentifier = Category.escalation
        content.threadIdentifier = "com.sight.escalation"

        let request = UNNotificationRequest(
            identifier: "escalation",
            content: content,
            trigger: nil
        )

        center.removeDeliveredNotifications(withIdentifiers: ["escalation"])

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error(
                        "Failed to send escalation notification: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Clear Methods

    /// Clear all pending notifications
    public func clearPendingNotifications() {
        center?.removeAllPendingNotificationRequests()
    }

    /// Clear all delivered notifications and badge
    public func clearDeliveredNotifications() {
        center?.removeAllDeliveredNotifications()
        clearBadge()
    }

    /// Clear the app badge count
    public func clearBadge() {
        Task { @MainActor in
            NSApplication.shared.dockTile.badgeLabel = nil
        }
    }

    /// Set badge count
    public func setBadge(_ count: Int) {
        Task { @MainActor in
            NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground
        return [.banner, .sound]
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        switch response.actionIdentifier {
        case Action.startBreak:
            await MainActor.run {
                // Post notification for proper timer handling
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightTakeBreak"), object: nil)
            }

        case Action.skip:
            logger.info("User skipped break via notification")
            await MainActor.run {
                // Skip the break in timer state machine
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightSkipBreak"), object: nil)
                // Record skip in adherence
                AdherenceManager.shared.recordBreak(completed: false, duration: 0)
            }

        case Action.postpone:
            logger.info("User postponed break for 5 minutes")
            await MainActor.run {
                // Postpone in timer state machine
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightPostponeBreak"),
                    object: nil,
                    userInfo: ["minutes": 5])
            }
            // Schedule a reminder in 5 minutes
            await schedulePostponedReminder()

        case Action.snooze:
            logger.info("User snoozed wellness reminder for 5 minutes")
            await MainActor.run {
                // Post snooze notification for MicroNudgesManager to handle
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightSnoozeNudge"),
                    object: nil,
                    userInfo: ["minutes": 5])
            }

        case Action.dismiss:
            logger.info("User dismissed wellness reminder")
            await MainActor.run {
                // Post dismiss notification for MicroNudgesManager
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightDismissNudge"), object: nil)
            }

        case Action.takeBreakNow:
            logger.info("User chose to take break from escalation notification")
            await MainActor.run {
                // Immediately trigger a break
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightTakeBreak"), object: nil)
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body - bring app to foreground
            logger.info("User tapped notification, activating app")
            await MainActor.run {
                NSApp.activate(ignoringOtherApps: true)
            }

        default:
            break
        }
    }

    private func schedulePostponedReminder() async {
        guard let center = center else { return }

        // Clear any existing postponed notifications to prevent duplicates
        center.removePendingNotificationRequests(withIdentifiers: ["postponed-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Break Reminder"
        content.body = "Time for that break you postponed!"
        content.sound = .default
        content.categoryIdentifier = Category.breakReminder
        content.threadIdentifier = threadIdentifier  // Group with other break notifications

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)

        // Use consistent identifier so we can clear it when user postpones again
        let request = UNNotificationRequest(
            identifier: "postponed-reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            logger.error("Failed to schedule postponed reminder: \(error.localizedDescription)")
        }
    }
}
