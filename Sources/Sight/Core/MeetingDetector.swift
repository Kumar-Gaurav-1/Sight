import Combine
import EventKit
import Foundation
import os.log

// MARK: - Meeting Detector

/// Detects calendar events to pause breaks during meetings
public final class MeetingDetector: ObservableObject {
    public static let shared = MeetingDetector()

    @Published public private(set) var isInMeeting: Bool = false
    @Published public private(set) var currentMeeting: String?
    @Published public private(set) var hasCalendarAccess: Bool = false

    private let eventStore = EKEventStore()
    private let logger = Logger(subsystem: "com.sight.app", category: "MeetingDetector")
    private var checkTimer: Timer?

    // MARK: - Initialization

    private init() {
        checkCalendarAccess()
        startMonitoring()
    }

    deinit {
        checkTimer?.invalidate()
    }

    // MARK: - Authorization

    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .fullAccess:
            hasCalendarAccess = true
            logger.info("Calendar access: authorized")
        case .writeOnly:
            hasCalendarAccess = false
            logger.info("Calendar access: writeOnly (insufficient)")
        case .notDetermined:
            hasCalendarAccess = false
            logger.info("Calendar access: not determined")
        case .restricted, .denied:
            hasCalendarAccess = false
            logger.info("Calendar access: denied/restricted")
        @unknown default:
            hasCalendarAccess = false
        }
    }

    /// Request calendar access
    public func requestAccess() async -> Bool {
        do {
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    hasCalendarAccess = granted
                    if granted {
                        logger.info("Calendar access granted - checking for meetings")
                        // Immediately check for meetings after access granted
                        checkForMeetings()
                    }
                }
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                await MainActor.run {
                    hasCalendarAccess = granted
                    if granted {
                        logger.info("Calendar access granted - checking for meetings")
                        // Immediately check for meetings after access granted
                        checkForMeetings()
                    }
                }
                return granted
            }
        } catch {
            logger.error("Calendar access error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Check every 30 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Periodically recheck calendar access in case user granted it via System Preferences
            if !self.hasCalendarAccess {
                self.checkCalendarAccess()
            }

            self.checkForMeetings()
        }

        // Initial check
        checkForMeetings()
    }

    public func checkForMeetings() {
        guard hasCalendarAccess else {
            // Log only once when access is missing
            if isInMeeting {
                logger.debug("Calendar access not available - cannot detect meetings")
            }
            isInMeeting = false
            currentMeeting = nil
            return
        }

        guard PreferencesManager.shared.meetingDetectionEnabled else {
            isInMeeting = false
            currentMeeting = nil
            return
        }

        let now = Date()
        let calendars = eventStore.calendars(for: .event)

        // Look for events happening now
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-60),  // 1 minute ago
            end: now.addingTimeInterval(60),  // 1 minute from now
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        // Filter to actual meetings (not all-day events)
        let meetings = events.filter { event in
            !event.isAllDay && event.startDate <= now && event.endDate > now
        }

        DispatchQueue.main.async { [weak self] in
            if let meeting = meetings.first {
                let wasInMeeting = self?.isInMeeting ?? false
                self?.isInMeeting = true
                self?.currentMeeting = meeting.title
                // Only log when entering a meeting
                if !wasInMeeting {
                    self?.logger.info("User is in a meeting (title redacted for privacy)")
                }
            } else {
                let wasInMeeting = self?.isInMeeting ?? false
                self?.isInMeeting = false
                self?.currentMeeting = nil
                // Only log when leaving a meeting
                if wasInMeeting {
                    self?.logger.info("User left meeting")
                }
            }
        }
    }

    /// Force refresh meeting status
    public func refresh() {
        checkCalendarAccess()
        checkForMeetings()
    }
}
