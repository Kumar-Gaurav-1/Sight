import AppKit
import Combine
import ScreenCaptureKit
import os.log

// MARK: - Pause Signal Priority

/// Pause signals with priority weights
/// Higher weight = stronger pause signal
public enum PauseSignal: String, CaseIterable, Codable {
    case screenRecording  // Weight: 100 - Definitive screen capture
    case screenSharing  // Weight: 95  - Active screen share
    case fullscreenVideo  // Weight: 90  - Fullscreen video app
    case meetingAppActive  // Weight: 80  - Known meeting app in foreground
    case fullscreenApp  // Weight: 70  - Any fullscreen application
    case focusModeActive  // Weight: 60  - Focus/DND enabled
    case presentationMode  // Weight: 85  - Presentation detected
    case calendarMeeting  // Weight: 50  - Calendar event now

    public var weight: Int {
        switch self {
        case .screenRecording: return 100
        case .screenSharing: return 95
        case .fullscreenVideo: return 90
        case .presentationMode: return 85
        case .meetingAppActive: return 80
        case .fullscreenApp: return 70
        case .focusModeActive: return 60
        case .calendarMeeting: return 50
        }
    }

    public var description: String {
        switch self {
        case .screenRecording: return "Screen recording active"
        case .screenSharing: return "Screen sharing detected"
        case .fullscreenVideo: return "Fullscreen video playing"
        case .presentationMode: return "Presentation mode"
        case .meetingAppActive: return "Meeting app in foreground"
        case .fullscreenApp: return "Fullscreen application"
        case .focusModeActive: return "Focus mode enabled"
        case .calendarMeeting: return "Calendar meeting in progress"
        }
    }
}

// MARK: - Known Meeting Apps

/// Bundle identifiers of known meeting/conferencing applications
public struct KnownMeetingApps {
    public static let bundleIdentifiers: Set<String> = [
        // Video conferencing
        "us.zoom.xos",  // Zoom
        "com.microsoft.teams",  // Microsoft Teams
        "com.microsoft.teams2",  // Microsoft Teams (new)
        "com.google.Chrome.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",  // Google Meet (Chrome app)
        "com.cisco.webexmeetingsapp",  // Webex
        "com.cisco.webex.meetings",  // Webex Meetings
        "com.bluejeans.BlueJeans",  // BlueJeans
        "com.gotomeeting.GoToMeeting",  // GoToMeeting
        "com.logmein.gotomeeting",  // GoToMeeting
        "com.slack.Slack",  // Slack (huddles)
        "com.discord.Discord",  // Discord
        "com.skype.skype",  // Skype
        "com.facetime",  // FaceTime
        "com.apple.FaceTime",  // FaceTime

        // Presentation
        "com.apple.Keynote",  // Keynote
        "com.microsoft.Powerpoint",  // PowerPoint
        "com.google.Chrome.app.aapocclcgogkmnckokdopfmhonfmgoek",  // Google Slides

        // Streaming
        "com.obsproject.obs-studio",  // OBS Studio
        "com.telestream.wirecast",  // Wirecast
        "tv.twitch.studio",  // Twitch Studio
        "com.loom.desktop",  // Loom
    ]

    public static let videoApps: Set<String> = [
        "com.apple.QuickTimePlayerX",
        "com.apple.TV",
        "org.videolan.vlc",
        "io.mpv",
        "com.netflix.Netflix",
        "com.disney.disneyplus",
    ]

    public static func isMeetingApp(_ bundleIdentifier: String) -> Bool {
        bundleIdentifiers.contains(bundleIdentifier)
    }

    public static func isVideoApp(_ bundleIdentifier: String) -> Bool {
        videoApps.contains(bundleIdentifier)
    }
}

// MARK: - Smart Pause Configuration

/// Configuration for Smart Pause behavior
public struct SmartPauseConfig: Codable {
    /// Minimum weight threshold to trigger pause
    /// Default 60 = Focus mode alone triggers pause (weight 60)
    /// Set to 80 to require meetings/screen recording (higher priority)
    public var pauseThreshold: Int = 60

    /// Polling interval for detection (seconds)
    public var pollingInterval: TimeInterval = 2.0

    /// Enable fullscreen detection (disabled by default to avoid false pauses)
    public var detectFullscreen: Bool = false

    /// Enable screen recording detection
    public var detectScreenRecording: Bool = true

    /// Enable Focus mode detection
    public var detectFocusMode: Bool = true

    /// Enable meeting app detection
    public var detectMeetingApps: Bool = true

    /// User-disabled signals (overrides)
    public var disabledSignals: Set<String> = []

    /// User-whitelisted apps (never pause for these)
    public var whitelistedApps: Set<String> = []

    public static let `default` = SmartPauseConfig()

    /// Conservative config that only pauses for high-priority signals
    public static let conservative = SmartPauseConfig(
        pauseThreshold: 80,
        detectFullscreen: false,
        detectFocusMode: false
    )

    public func isSignalEnabled(_ signal: PauseSignal) -> Bool {
        !disabledSignals.contains(signal.rawValue)
    }
}

// MARK: - Smart Pause Manager

/// Manages intelligent pause detection for break timers
/// Uses multiple heuristics to detect when user should not be interrupted
///
/// References:
/// - ScreenCaptureKit: https://developer.apple.com/documentation/screencapturekit
/// - Focus APIs: NSDistributedNotificationCenter for focus state changes
public final class SmartPauseManager: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var shouldPause: Bool = false
    @Published public private(set) var activeSignals: [PauseSignal] = []
    @Published public private(set) var totalWeight: Int = 0

    // MARK: - Configuration

    public var config: SmartPauseConfig {
        didSet { saveConfig() }
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.kumargaurav.Sight", category: "SmartPause")
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var focusObserver: NSObjectProtocol?
    private var screenCaptureObserver: NSObjectProtocol?
    // SECURITY: Store all observers to ensure proper cleanup
    private var focusStateObserver: NSObjectProtocol?
    private var appActivationObserver: NSObjectProtocol?
    private var spaceChangeObserver: NSObjectProtocol?

    // Dedicated queue for detection to avoid blocking main thread
    private let detectionQueue = DispatchQueue(
        label: "com.sight.smartpause.detection", qos: .userInitiated)

    // Detection state
    private var isScreenBeingCaptured = false
    private var lastDetectionTime: Date?

    // MARK: - Singleton

    public static let shared = SmartPauseManager()

    // MARK: - Initialization

    public init(config: SmartPauseConfig = .default) {
        self.config = config

        // Load saved config if available
        if let savedConfig = Self.loadSavedConfig() {
            self.config = savedConfig
        }

        setupObservers()
    }

    deinit {
        stopMonitoring()
        removeObservers()
    }

    // MARK: - Public API

    /// Start monitoring for pause signals
    public func startMonitoring() {
        logger.info("Starting Smart Pause monitoring")

        // Sync with PreferencesManager settings
        let prefs = PreferencesManager.shared
        config.detectMeetingApps = prefs.meetingDetectionEnabled
        config.detectFullscreen = prefs.pauseForFullscreenApps

        // Subscribe to preference changes for reactive updates
        prefs.$meetingDetectionEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.config.detectMeetingApps = enabled
                self?.logger.debug("Meeting detection updated: \(enabled)")
            }
            .store(in: &cancellables)

        prefs.$pauseForFullscreenApps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.config.detectFullscreen = enabled
                self?.logger.debug("Fullscreen detection updated: \(enabled)")
            }
            .store(in: &cancellables)

        // Initial detection
        refresh()

        // Start polling timer
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: config.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.refresh()
        }

        // Start ScreenCaptureKit monitoring if available
        if config.detectScreenRecording {
            startScreenCaptureMonitoring()
        }
    }

    /// Stop monitoring
    public func stopMonitoring() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        logger.info("Stopped Smart Pause monitoring")
    }

    /// Force refresh detection
    public func refresh() {
        // Run on background queue
        detectionQueue.async { [weak self] in
            self?.detectAll()
        }
    }

    /// User override: temporarily ignore pause signals
    public func overridePause(duration: TimeInterval) {
        logger.info("User override for \(duration)s")
        // Implementation: temporarily disable shouldPause
        // Note: For now, this is just a stub as per original file
    }

    // MARK: - Detection Logic

    private func detectAll() {
        // Ensure this runs on background queue implicitly by being called from refresh()

        var signals: [PauseSignal] = []

        // 1. Fullscreen detection
        if config.detectFullscreen {
            if let fsSignal = detectFullscreen() {
                signals.append(fsSignal)
            }
        }

        // 2. Screen recording/sharing
        if config.detectScreenRecording {
            signals.append(contentsOf: detectScreenCapture())
        }

        // 3. Meeting app detection
        if config.detectMeetingApps {
            if let appSignal = detectMeetingApp() {
                signals.append(appSignal)
            }
        }

        // 4. Calendar meeting detection (from MeetingDetector)
        if config.detectMeetingApps {
            // Safely check meeting status - avoid deadlock if already on main thread
            var isInMeeting = false
            if Thread.isMainThread {
                isInMeeting = MeetingDetector.shared.isInMeeting
            } else {
                DispatchQueue.main.sync {
                    isInMeeting = MeetingDetector.shared.isInMeeting
                }
            }
            if isInMeeting {
                signals.append(.calendarMeeting)
            }
        }

        // 5. Focus mode
        if config.detectFocusMode {
            if detectFocusMode() {
                signals.append(.focusModeActive)
            }
        }

        // Filter by user preferences
        let filteredSignals = signals.filter { config.isSignalEnabled($0) }

        // Calculate total weight
        let weight = filteredSignals.reduce(0) { $0 + $1.weight }

        // Update state on Main Thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activeSignals = filteredSignals
            self.totalWeight = weight
            self.shouldPause = weight >= self.config.pauseThreshold
            self.lastDetectionTime = Date()
        }

        if !filteredSignals.isEmpty {
            // logger.debug(...) // Optional logging
        }
    }

    // MARK: - Fullscreen Detection

    private func detectFullscreen() -> PauseSignal? {
        // Method 1: Check key window fullscreen style mask
        // IGNORE internal windows to avoid self-pausing (e.g. Break Overlay)
        // if let keyWindow = NSApplication.shared.keyWindow, ...
        // We only care about OTHER apps being fullscreen

        // Method 2: Check frontmost application
        if let frontApp = NSWorkspace.shared.frontmostApplication,
            let bundleId = frontApp.bundleIdentifier
        {

            // Ignore ourselves
            if bundleId == Bundle.main.bundleIdentifier {
                return nil
            }

            // Check if app is in presentation mode
            if isAppInPresentationMode(bundleId) {
                return .presentationMode
            }

            // Check if fullscreen via CGWindow
            if isAppFullscreen(frontApp) {
                if KnownMeetingApps.isVideoApp(bundleId) {
                    return .fullscreenVideo
                }
                return .fullscreenApp
            }
        }

        return nil
    }

    private func isAppFullscreen(_ app: NSRunningApplication) -> Bool {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard
            let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return false
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                ownerPID == app.processIdentifier,
                let bounds = window[kCGWindowBounds as String] as? [String: CGFloat]
            else {
                continue
            }

            let windowSize = CGSize(
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )

            // Use CoreGraphics for thread-safe screen bounds
            let mainDisplay = CGMainDisplayID()
            let screenBounds = CGDisplayBounds(mainDisplay)

            // Check if window fills screen
            // Allow for slight rounding errors or menu bar exclusion
            if windowSize.width >= screenBounds.width
                && windowSize.height >= (screenBounds.height - 50)
            {  // Approx menu bar allowance
                return true
            }
        }

        return false
    }

    private func isAppInPresentationMode(_ bundleId: String) -> Bool {
        // Keynote/PowerPoint presentation detection
        let presentationApps = ["com.apple.Keynote", "com.microsoft.Powerpoint"]
        if presentationApps.contains(bundleId) {
            // Check if in slideshow mode by window title or properties
            // SECURITY: Safely unwrap frontmostApplication to avoid crash
            guard let frontApp = NSWorkspace.shared.frontmostApplication else {
                return false
            }
            return isAppFullscreen(frontApp)
        }
        return false
    }

    // MARK: - Screen Capture Detection

    /// Detects active screen recording or sharing
    /// Uses ScreenCaptureKit (macOS 12.3+) with fallback heuristics
    ///
    /// Reference: https://developer.apple.com/documentation/screencapturekit
    private func detectScreenCapture() -> [PauseSignal] {
        var signals: [PauseSignal] = []

        // Check cached ScreenCaptureKit result
        if isScreenBeingCaptured {
            signals.append(.screenRecording)
        }

        // Fallback 1: Check for screensharingd process
        if isScreenSharingDaemonRunning() {
            signals.append(.screenSharing)
        }

        // Fallback 2: Check for known screen recording apps
        if let signal = detectScreenRecordingApps() {
            signals.append(signal)
        }

        return signals
    }

    /// Start ScreenCaptureKit monitoring for capture detection
    /// Available on macOS 12.3+
    private func startScreenCaptureMonitoring() {
        guard #available(macOS 12.3, *) else {
            logger.info("ScreenCaptureKit unavailable, using fallback heuristics")
            return
        }

        // ScreenCaptureKit provides SCContentSharingPicker and stream detection
        // For privacy, we can't directly monitor other app's captures,
        // but we can check if our app has any active capture sessions

        // Poll SCShareableContent for changes that might indicate capture
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )

                // Log available content (for debugging)
                logger.debug(
                    "SCShareableContent: \(content.displays.count) displays, \(content.windows.count) windows"
                )

            } catch {
                logger.warning("SCShareableContent unavailable: \(error.localizedDescription)")
            }
        }

        // Additional: Monitor for system screen capture indicator
        // The menubar shows a recording indicator when capture is active
        // This is a heuristic approximation
    }

    /// Check if screensharingd daemon is running (indicates active screen share)
    /// SECURITY: Uses only native NSWorkspace API, no shell command execution
    private func isScreenSharingDaemonRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications

        // Check for screen sharing related processes by bundle ID and name
        let screenShareBundleIds = [
            "com.apple.screensharing.agent",
            "com.apple.ScreenSharing",
        ]

        let screenShareProcessNames = [
            "screensharingd",
            "ScreensharingAgent",
            "Screen Sharing",
        ]

        for app in runningApps {
            // Check by bundle identifier (most reliable)
            if let bundleId = app.bundleIdentifier,
                screenShareBundleIds.contains(where: { bundleId.contains($0) })
            {
                return true
            }

            // Check by localized name
            if let name = app.localizedName,
                screenShareProcessNames.contains(where: { name.contains($0) })
            {
                return true
            }

            // Check by executable name
            if let executableURL = app.executableURL,
                screenShareProcessNames.contains(where: {
                    executableURL.lastPathComponent.contains($0)
                })
            {
                return true
            }
        }

        return false
    }

    /// Detect foreground apps that are likely screen recording
    private func detectScreenRecordingApps() -> PauseSignal? {
        let recordingApps = [
            "com.obsproject.obs-studio",
            "com.loom.desktop",
            "tv.twitch.studio",
            "com.telestream.wirecast",
        ]

        if let frontApp = NSWorkspace.shared.frontmostApplication,
            let bundleId = frontApp.bundleIdentifier,
            recordingApps.contains(bundleId)
        {
            return .screenRecording
        }

        return nil
    }

    // MARK: - Meeting App Detection

    private func detectMeetingApp() -> PauseSignal? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
            let bundleId = frontApp.bundleIdentifier
        else {
            return nil
        }

        // Check if app is whitelisted by user
        if config.whitelistedApps.contains(bundleId) {
            return nil
        }

        if KnownMeetingApps.isMeetingApp(bundleId) {
            return .meetingAppActive
        }

        return nil
    }

    // MARK: - Focus Mode Detection

    /// Detect Focus Mode (Do Not Disturb) status
    /// Uses NSDistributedNotificationCenter and UserDefaults heuristics
    private func detectFocusMode() -> Bool {
        // Method 1: Check DND defaults
        if let dndDefaults = UserDefaults(suiteName: "com.apple.ncprefs") {
            if dndDefaults.bool(forKey: "doNotDisturb") {
                return true
            }
        }

        // Method 2: Check Focus status via notification center prefs
        // This is a heuristic as direct Focus API requires entitlements
        if let focusDefaults = UserDefaults(suiteName: "com.apple.FocusSystem") {
            if focusDefaults.object(forKey: "FocusIsOnKey") as? Bool == true {
                return true
            }
        }

        return false
    }

    // MARK: - Observers

    private func setupObservers() {
        // Focus mode changes
        focusObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.doNotDisturbModeDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectAll()
        }

        // Alternative Focus notification
        // SECURITY: Store observer to ensure cleanup
        focusStateObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.focusstatechanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectAll()
        }

        // App activation changes
        // SECURITY: Store observer to ensure cleanup
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectAll()
        }

        // Space changes (fullscreen detection)
        // SECURITY: Store observer to ensure cleanup
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectAll()
        }
    }

    private func removeObservers() {
        // SECURITY: Remove all stored observers to prevent memory leaks
        if let observer = focusObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            focusObserver = nil
        }
        if let observer = focusStateObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            focusStateObserver = nil
        }
        if let observer = appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appActivationObserver = nil
        }
        if let observer = spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            spaceChangeObserver = nil
        }
        // SECURITY: Also clean up screenCaptureObserver if it was stored
        if let observer = screenCaptureObserver {
            NotificationCenter.default.removeObserver(observer)
            screenCaptureObserver = nil
        }
    }

    // MARK: - Persistence

    private static func loadSavedConfig() -> SmartPauseConfig? {
        guard let data = UserDefaults.standard.data(forKey: "SmartPauseConfig"),
            let config = try? JSONDecoder().decode(SmartPauseConfig.self, from: data)
        else {
            return nil
        }
        return config
    }

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "SmartPauseConfig")
        }
    }
}

// MARK: - Priority Table (Documentation)

/*
 ┌─────────────────────────┬────────┬─────────────────────────────────────────┐
 │ Signal                  │ Weight │ Detection Method                        │
 ├─────────────────────────┼────────┼─────────────────────────────────────────┤
 │ screenRecording         │ 100    │ ScreenCaptureKit, OBS/Loom detection    │
 │ screenSharing           │ 95     │ screensharingd process check            │
 │ fullscreenVideo         │ 90     │ Fullscreen + video app bundle ID        │
 │ presentationMode        │ 85     │ Keynote/PowerPoint fullscreen           │
 │ meetingAppActive        │ 80     │ Known meeting app in foreground         │
 │ fullscreenApp           │ 70     │ Any app in fullscreen mode              │
 │ focusModeActive         │ 60     │ DND/Focus via UserDefaults              │
 │ calendarMeeting         │ 50     │ EventKit integration (future)           │
 └─────────────────────────┴────────┴─────────────────────────────────────────┘

 Threshold: 60 (default) - Focus mode alone will trigger pause

 User Overrides:
 - config.disabledSignals: Set of signal names to ignore
 - config.whitelistedApps: Bundle IDs that never trigger pause
*/

// MARK: - Integration with Timer

extension SmartPauseManager {

    /// Integrate with TimerStateMachine for automatic pausing
    public func integrate(with stateMachine: TimerStateMachine) -> AnyCancellable {
        return
            $shouldPause
            .removeDuplicates()
            .sink { [weak stateMachine] shouldPause in
                guard let sm = stateMachine else { return }

                // SECURITY: Dispatch to MainActor to access main-actor-isolated properties
                Task { @MainActor in
                    if shouldPause && sm.currentState != .idle {
                        // Timer is running and we should pause
                        // Note: Actual pause logic depends on state machine design
                        // This could set a "paused" flag or stop the timer
                    }
                }
            }
    }
}
