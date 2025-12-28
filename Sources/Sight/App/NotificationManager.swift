import Foundation
import UserNotifications
import os.log

/// Manages system notifications for break reminders
/// Handles gracefully when running without proper app bundle (e.g., SPM executable)
public final class NotificationManager: NSObject, ObservableObject {

    public static let shared = NotificationManager()

    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var isAvailable: Bool = false

    private let logger = Logger(subsystem: "com.sight.app", category: "Notifications")
    private var center: UNUserNotificationCenter?

    // MARK: - Notification Categories

    private enum Category {
        static let breakReminder = "BREAK_REMINDER"
        static let preBreak = "PRE_BREAK"
    }

    private enum Action {
        static let startBreak = "START_BREAK"
        static let skip = "SKIP"
        static let postpone = "POSTPONE"
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

        let breakCategory = UNNotificationCategory(
            identifier: Category.breakReminder,
            actions: [startAction, skipAction, postponeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let preBreakCategory = UNNotificationCategory(
            identifier: Category.preBreak,
            actions: [startAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([breakCategory, preBreakCategory])
    }

    // MARK: - Send Notifications

    /// Send a pre-break warning notification
    public func sendPreBreakNotification(secondsRemaining: Int) {
        guard let center = center, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Break Coming Up"
        content.body = "Take a break in \(secondsRemaining) seconds"
        content.sound = .default
        content.categoryIdentifier = Category.preBreak

        let request = UNNotificationRequest(
            identifier: "preBreak-\(UUID().uuidString)",
            content: content,
            trigger: nil  // Immediate
        )

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
        content.body = "Look away from the screen for \(durationSeconds) seconds"
        content.sound = .default
        content.categoryIdentifier = Category.breakReminder

        let request = UNNotificationRequest(
            identifier: "breakStart-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

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
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: "breakEnd-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error(
                    "Failed to send break end notification: \(error.localizedDescription)")
            }
        }
    }

    /// Clear all pending notifications
    public func clearPendingNotifications() {
        center?.removeAllPendingNotificationRequests()
    }

    /// Clear all delivered notifications
    public func clearDeliveredNotifications() {
        center?.removeAllDeliveredNotifications()
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
            // Record skip in adherence
            await MainActor.run {
                AdherenceManager.shared.recordBreak(completed: false, duration: 0)
            }

        case Action.postpone:
            logger.info("User postponed break for 5 minutes")
            // Schedule a reminder in 5 minutes
            await schedulePostponedReminder()

        default:
            break
        }
    }

    private func schedulePostponedReminder() async {
        guard let center = center else { return }

        let content = UNMutableNotificationContent()
        content.title = "Break Reminder"
        content.body = "Time for that break you postponed!"
        content.sound = .default
        content.categoryIdentifier = Category.breakReminder

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: "postponed-\(UUID().uuidString)",
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
