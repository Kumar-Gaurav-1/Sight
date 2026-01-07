import AppKit
import Combine
import Foundation
import os.log

// MARK: - Work Hours Manager

/// Manages work hour scheduling (quiet hours, active days, fullscreen detection)
public final class WorkHoursManager: ObservableObject {
    public static let shared = WorkHoursManager()

    @Published public private(set) var shouldPauseForSchedule: Bool = false
    @Published public private(set) var pauseReason: String?
    @Published public private(set) var isFullscreenAppActive: Bool = false

    private let logger = Logger(subsystem: "com.kumargaurav.Sight.app", category: "WorkHours")
    private var checkTimer: Timer?
    private var fullscreenObserver: Any?

    private init() {
        startMonitoring()
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    /// Check if breaks should be paused based on schedule
    public func shouldPause() -> Bool {
        let prefs = PreferencesManager.shared

        // Check working hours - pause if OUTSIDE configured working hours
        if prefs.quietHoursEnabled && !isWithinWorkingHours() {
            pauseReason = "Outside Working Hours"
            shouldPauseForSchedule = true
            return true
        }

        // Check active days
        if !isActiveDay() {
            pauseReason = "Rest Day"
            shouldPauseForSchedule = true
            return true
        }

        // Check fullscreen apps
        if prefs.pauseForFullscreenApps && isFullscreenAppActive {
            pauseReason = "Fullscreen App"
            shouldPauseForSchedule = true
            return true
        }

        pauseReason = nil
        shouldPauseForSchedule = false
        return false
    }

    // MARK: - Working Hours (formerly "Quiet Hours")

    /// Returns true if current time is WITHIN the configured working hours
    /// When enabled, the app should only remind during these hours
    private func isWithinWorkingHours() -> Bool {
        let prefs = PreferencesManager.shared
        guard prefs.quietHoursEnabled else { return true }  // If disabled, always "working"

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // prefs store hours (0-23), not minutes
        // These represent ACTIVE working hours (e.g., 9-17 means work from 9am to 5pm)
        let startHour = prefs.quietHoursStart
        let endHour = prefs.quietHoursEnd

        // Handle overnight working hours (unusual but possible)
        if startHour > endHour {
            // e.g. 22 to 6: working if currentHour >= 22 OR currentHour < 6
            return currentHour >= startHour || currentHour < endHour
        } else {
            // e.g. 9 to 17: working if 9 <= currentHour < 17
            return currentHour >= startHour && currentHour < endHour
        }
    }

    // MARK: - Active Days

    private func isActiveDay() -> Bool {
        let prefs = PreferencesManager.shared
        let weekday = Calendar.current.component(.weekday, from: Date())

        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // activeDays: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        let index: Int
        switch weekday {
        case 1: index = 6  // Sunday
        case 2: index = 0  // Monday
        case 3: index = 1  // Tuesday
        case 4: index = 2  // Wednesday
        case 5: index = 3  // Thursday
        case 6: index = 4  // Friday
        case 7: index = 5  // Saturday
        default: index = 0
        }

        guard index < prefs.activeDays.count else { return true }
        return prefs.activeDays[index]
    }

    // MARK: - Fullscreen Detection

    private func checkFullscreenApps() {
        guard PreferencesManager.shared.pauseForFullscreenApps else {
            isFullscreenAppActive = false
            return
        }

        // Check if any window is fullscreen
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            isFullscreenAppActive = false
            return
        }

        let screenFrame = NSScreen.main?.frame ?? .zero

        for window in windowList {
            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                let layer = window[kCGWindowLayer as String] as? Int,
                layer == 0
            else { continue }

            let windowWidth = bounds["Width"] ?? 0
            let windowHeight = bounds["Height"] ?? 0

            // Check if window covers the entire screen
            if windowWidth >= screenFrame.width && windowHeight >= screenFrame.height {
                // Exclude Finder and Dock
                if let ownerName = window[kCGWindowOwnerName as String] as? String,
                    ownerName != "Finder" && ownerName != "Dock" && ownerName != "Sight"
                {
                    isFullscreenAppActive = true
                    logger.debug("Fullscreen app detected: \(ownerName)")
                    return
                }
            }
        }

        isFullscreenAppActive = false
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Check every 30 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkFullscreenApps()
            _ = self?.shouldPause()
        }

        // Initial check
        checkFullscreenApps()
        _ = shouldPause()

        // Observe screen changes
        fullscreenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkFullscreenApps()
        }
    }

    private func stop() {
        checkTimer?.invalidate()
        checkTimer = nil

        if let observer = fullscreenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Force refresh
    public func refresh() {
        checkFullscreenApps()
        _ = shouldPause()
    }
}
