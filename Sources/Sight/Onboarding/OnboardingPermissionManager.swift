import AppKit
import Combine
import EventKit
import ScreenCaptureKit
import SwiftUI
import UserNotifications
import os.log

// MARK: - Permission State

public enum PermissionState: String, Equatable {
    case notDetermined = "Not Determined"
    case granted = "Granted"
    case denied = "Denied"
    case restricted = "Restricted"

    var icon: String {
        switch self {
        case .notDetermined: return "circle"
        case .granted: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .restricted: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notDetermined: return .gray
        case .granted: return .green
        case .denied: return .red
        case .restricted: return .orange
        }
    }

    var isGranted: Bool {
        self == .granted
    }
}

// MARK: - Permission Type

public enum PermissionType: String, CaseIterable, Identifiable {
    case notifications = "Notifications"
    case screenRecording = "Screen Recording"
    case calendar = "Calendar"
    case accessibility = "Accessibility"

    public var id: String { rawValue }

    var icon: String {
        switch self {
        case .notifications: return "bell.badge.fill"
        case .screenRecording: return "rectangle.dashed.badge.record"
        case .calendar: return "calendar"
        case .accessibility: return "accessibility"
        }
    }

    var iconColor: Color {
        switch self {
        case .notifications: return .red
        case .screenRecording: return .purple
        case .calendar: return .orange
        case .accessibility: return .blue
        }
    }

    var title: String {
        rawValue
    }

    var subtitle: String {
        switch self {
        case .notifications:
            return "Get notified when it's time for a break"
        case .screenRecording:
            return "Detect fullscreen apps to pause breaks automatically"
        case .calendar:
            return "Pause breaks during meetings"
        case .accessibility:
            return "Enable global keyboard shortcuts"
        }
    }

    var explanation: String {
        switch self {
        case .notifications:
            return
                "Sight sends gentle reminders when breaks are due. Without notifications, you'll only see the menu bar timer change."
        case .screenRecording:
            return
                "This lets Sight detect when you're in fullscreen mode (videos, presentations) or screen sharing, so breaks won't interrupt. Sight does NOT record your screen."
        case .calendar:
            return
                "Sight checks if you have an active calendar event to pause breaks during meetings. Only event timing is checked – details stay private."
        case .accessibility:
            return
                "Required for global keyboard shortcuts (like quickly skipping a break). Without this, shortcuts only work when Sight is focused."
        }
    }

    var isRequired: Bool {
        switch self {
        case .notifications: return true
        case .screenRecording: return false
        case .calendar: return false
        case .accessibility: return false
        }
    }

    var skipConsequence: String {
        switch self {
        case .notifications:
            return "You won't receive break reminders"
        case .screenRecording:
            return "Breaks may interrupt fullscreen videos"
        case .calendar:
            return "Breaks will occur during meetings"
        case .accessibility:
            return "Keyboard shortcuts won't work globally"
        }
    }
}

// MARK: - Onboarding Permission Manager

@MainActor
public final class OnboardingPermissionManager: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var notificationStatus: PermissionState = .notDetermined
    @Published public private(set) var screenRecordingStatus: PermissionState = .notDetermined
    @Published public private(set) var calendarStatus: PermissionState = .notDetermined
    @Published public private(set) var accessibilityStatus: PermissionState = .notDetermined

    @Published public private(set) var isCheckingPermissions = false

    // Per-permission loading states
    @Published public private(set) var isLoadingNotifications = false
    @Published public private(set) var isLoadingScreenRecording = false
    @Published public private(set) var isLoadingCalendar = false
    @Published public private(set) var isLoadingAccessibility = false

    // MARK: - Private

    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "Permissions")
    private let eventStore = EKEventStore()
    private var accessibilityPollingTimer: Timer?

    // MARK: - Singleton

    public static let shared = OnboardingPermissionManager()

    private init() {
        Task {
            await refreshAllStatuses()
        }
    }

    // MARK: - Accessibility Polling

    /// Start polling accessibility status (for auto-refresh after System Settings)
    public func startAccessibilityPolling() {
        stopAccessibilityPolling()
        accessibilityPollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
            [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAccessibilityStatus()
            }
        }
    }

    public func stopAccessibilityPolling() {
        accessibilityPollingTimer?.invalidate()
        accessibilityPollingTimer = nil
    }

    // MARK: - Status Helpers

    public func status(for type: PermissionType) -> PermissionState {
        switch type {
        case .notifications: return notificationStatus
        case .screenRecording: return screenRecordingStatus
        case .calendar: return calendarStatus
        case .accessibility: return accessibilityStatus
        }
    }

    public var allRequiredGranted: Bool {
        PermissionType.allCases
            .filter { $0.isRequired }
            .allSatisfy { status(for: $0).isGranted }
    }

    public var grantedCount: Int {
        PermissionType.allCases.filter { status(for: $0).isGranted }.count
    }

    // MARK: - Refresh All

    public func refreshAllStatuses() async {
        isCheckingPermissions = true
        defer { isCheckingPermissions = false }

        await checkNotificationStatus()
        await checkScreenRecordingStatus()
        await checkCalendarStatus()
        checkAccessibilityStatus()
    }

    // MARK: - Notifications

    public func checkNotificationStatus() async {
        // Guard against unbundled execution (e.g. swift run) to prevent crashes
        guard Bundle.main.bundleIdentifier != nil else {
            notificationStatus = .notDetermined
            logger.warning("Bundle identifier missing - skipping notification check")
            return
        }

        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            notificationStatus = .notDetermined
        case .denied:
            notificationStatus = .denied
        case .authorized, .provisional, .ephemeral:
            notificationStatus = .granted
        @unknown default:
            notificationStatus = .notDetermined
        }

        logger.debug("Notification status: \(self.notificationStatus.rawValue)")
    }

    public func requestNotifications() async -> Bool {
        // Guard against unbundled execution
        guard Bundle.main.bundleIdentifier != nil else {
            logger.error("Cannot request notifications: Bundle identifier missing")
            notificationStatus = .denied
            return false
        }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            notificationStatus = granted ? .granted : .denied
            logger.info("Notifications \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Notification request failed: \(error.localizedDescription)")
            notificationStatus = .denied
            return false
        }
    }

    // MARK: - Screen Recording

    public func checkScreenRecordingStatus() async {
        guard #available(macOS 12.3, *) else {
            screenRecordingStatus = .restricted
            return
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            screenRecordingStatus = content.displays.isEmpty ? .denied : .granted
        } catch {
            screenRecordingStatus = .denied
        }

        logger.debug("Screen recording status: \(self.screenRecordingStatus.rawValue)")
    }

    public func requestScreenRecording() async -> Bool {
        guard #available(macOS 12.3, *) else {
            screenRecordingStatus = .restricted
            return false
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            let granted = !content.displays.isEmpty
            screenRecordingStatus = granted ? .granted : .denied
            logger.info("Screen recording \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Screen recording request failed: \(error.localizedDescription)")
            screenRecordingStatus = .denied
            return false
        }
    }

    // MARK: - Calendar

    public func checkCalendarStatus() async {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .notDetermined:
            calendarStatus = .notDetermined
        case .restricted:
            calendarStatus = .restricted
        case .denied:
            calendarStatus = .denied
        case .fullAccess, .writeOnly:
            calendarStatus = .granted
        @unknown default:
            calendarStatus = .notDetermined
        }

        logger.debug("Calendar status: \(self.calendarStatus.rawValue)")
    }

    public func requestCalendar() async -> Bool {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }

            calendarStatus = granted ? .granted : .denied
            logger.info("Calendar \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Calendar request failed: \(error.localizedDescription)")
            calendarStatus = .denied
            return false
        }
    }

    // MARK: - Accessibility

    public func checkAccessibilityStatus() {
        let trusted = AXIsProcessTrusted()
        accessibilityStatus = trusted ? .granted : .notDetermined

        logger.debug("Accessibility status: \(self.accessibilityStatus.rawValue)")
    }

    public func requestAccessibility() -> Bool {
        // First check current status
        if AXIsProcessTrusted() {
            accessibilityStatus = .granted
            return true
        }

        // Prompt for access (this opens System Settings)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        accessibilityStatus = trusted ? .granted : .notDetermined
        logger.info("Accessibility prompt shown, trusted: \(trusted)")
        return trusted
    }

    public func openAccessibilitySettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Generic Request

    public func request(_ type: PermissionType) async -> Bool {
        switch type {
        case .notifications:
            return await requestNotifications()
        case .screenRecording:
            return await requestScreenRecording()
        case .calendar:
            return await requestCalendar()
        case .accessibility:
            return requestAccessibility()
        }
    }

    public func openSettings(for type: PermissionType) {
        let urlString: String

        switch type {
        case .notifications:
            if let bundleID = Bundle.main.bundleIdentifier {
                urlString =
                    "x-apple.systempreferences:com.apple.preference.notifications?bundleID=\(bundleID)"
            } else {
                urlString = "x-apple.systempreferences:com.apple.preference.notifications"
            }
        case .screenRecording:
            urlString =
                "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .calendar:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        case .accessibility:
            urlString =
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Permission Card View

struct PermissionCardView: View {
    let type: PermissionType
    @ObservedObject var manager: OnboardingPermissionManager = .shared

    @State private var isHovered = false
    @State private var isRequesting = false
    @State private var showExplanation = false

    private var status: PermissionState {
        manager.status(for: type)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(type.iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(type.iconColor)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(type.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        if type.isRequired {
                            Text("Required")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.red.opacity(0.8)))
                        }
                    }

                    Text(type.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Status / Action
                if status.isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if isRequesting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 80)
                } else {
                    Button(status == .denied ? "Open Settings" : "Allow") {
                        requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(type.iconColor)
                    .controlSize(.small)
                }
            }
            .padding(16)

            // Expandable explanation
            if showExplanation {
                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Why this permission?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(type.explanation)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if status == .denied {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Permission was denied. You can enable it in System Settings.")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            status.isGranted ? Color.green.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4)
        )
        .scaleEffect(isHovered ? 1.01 : 1)
        .animation(.spring(response: 0.3), value: isHovered)
        .animation(.spring(response: 0.3), value: status)
        .animation(.spring(response: 0.3), value: showExplanation)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            withAnimation {
                showExplanation.toggle()
            }
        }
    }

    private func requestPermission() {
        isRequesting = true

        if status == .denied {
            manager.openSettings(for: type)
            isRequesting = false
        } else {
            Task {
                _ = await manager.request(type)
                isRequesting = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Permission Cards") {
    VStack(spacing: 12) {
        ForEach(PermissionType.allCases) { type in
            PermissionCardView(type: type)
        }
    }
    .padding()
    .frame(width: 500)
    .background(Color(NSColor.windowBackgroundColor))
}
