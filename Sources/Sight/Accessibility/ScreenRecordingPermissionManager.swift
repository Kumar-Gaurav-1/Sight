import AppKit
import ScreenCaptureKit
import SwiftUI
import os.log

/// Manager for Screen Recording permission
/// Handles permission requests and status monitoring for ScreenCaptureKit
@MainActor
public final class ScreenRecordingPermissionManager: ObservableObject {

    public static let shared = ScreenRecordingPermissionManager()

    @Published public private(set) var hasPermission: Bool = false
    @Published public private(set) var permissionStatus: PermissionStatus = .notDetermined

    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "ScreenRecording")

    public enum PermissionStatus {
        case notDetermined
        case granted
        case denied
        case restricted
    }

    private init() {}

    // MARK: - Permission Checking

    /// Check current screen recording permission status
    /// Available on macOS 12.3+ where ScreenCaptureKit is available
    public func checkPermissionStatus() async {
        guard #available(macOS 12.3, *) else {
            logger.warning("ScreenCaptureKit unavailable on this macOS version")
            permissionStatus = .restricted
            hasPermission = false
            return
        }

        do {
            // Try to get shareable content - this will trigger permission prompt if needed
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            // If we got content, we have permission
            hasPermission = !content.displays.isEmpty
            permissionStatus = hasPermission ? .granted : .denied

            logger.info("Screen recording permission: \\(self.permissionStatus)")

        } catch {
            // Permission denied or error occurred
            hasPermission = false
            permissionStatus = .denied
            logger.warning(
                "Screen recording permission check failed: \\(error.localizedDescription)")
        }
    }

    // MARK: - Permission Request

    /// Request screen recording permission
    /// This will show the system permission dialog if not already determined
    public func requestPermission() async -> Bool {
        guard #available(macOS 12.3, *) else {
            logger.warning("ScreenCaptureKit unavailable - cannot request permission")
            showUnsupportedVersionAlert()
            return false
        }

        do {
            // Attempt to access shareable content - this triggers permission prompt
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            let granted = !content.displays.isEmpty
            hasPermission = granted
            permissionStatus = granted ? .granted : .denied

            if granted {
                logger.info("Screen recording permission granted")
            } else {
                logger.warning("Screen recording permission denied")
                showPermissionDeniedAlert()
            }

            return granted

        } catch {
            hasPermission = false
            permissionStatus = .denied
            logger.error(
                "Failed to request screen recording permission: \\(error.localizedDescription)")
            showPermissionDeniedAlert()
            return false
        }
    }

    // MARK: - User Guidance

    /// Show alert explaining screen recording is needed
    public func showPermissionExplanation() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Needed"
        alert.informativeText = """
            Sight needs screen recording permission to detect:

            • Fullscreen videos and presentations
            • Screen sharing sessions
            • Recording apps (OBS, Loom, etc.)

            This allows breaks to pause automatically during these activities, so you're not interrupted.

            Note: Sight does NOT actually record your screen. This permission is only used for detection.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Grant Permission")
        alert.addButton(withTitle: "Not Now")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            Task {
                await requestPermission()
            }
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Denied"
        alert.informativeText = """
            To enable Smart Pause features, you need to grant screen recording access:

            1. Open System Settings
            2. Go to Privacy & Security → Screen Recording
            3. Enable the checkbox next to "Sight"
            4. Restart Sight

            Without this permission, Smart Pause won't be able to detect fullscreen apps or screen sharing.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Continue Without")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }

    private func showUnsupportedVersionAlert() {
        let alert = NSAlert()
        alert.messageText = "macOS Version Too Old"
        alert.informativeText = """
            Screen recording detection requires macOS 12.3 or later.

            Smart Pause will use alternative detection methods, but may be less accurate at detecting fullscreen content.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Open System Settings to Screen Recording panel
    public func openSystemPreferences() {
        if #available(macOS 13.0, *) {
            // macOS 13+ uses new Settings URL scheme
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(url)
        } else {
            // macOS 12 uses old System Preferences
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(url)
        }
    }
}
