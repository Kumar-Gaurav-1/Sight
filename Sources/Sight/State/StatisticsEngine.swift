import Combine
import Foundation
import os.log

// MARK: - Pause Reason

/// Reasons for timer pause events
public enum PauseReason: String, Codable, CaseIterable, Sendable {
    case meeting = "meeting"
    case screenRecording = "screenRecording"
    case fullscreen = "fullscreen"
    case idle = "idle"
    case manual = "manual"
    case quietHours = "quietHours"
    case systemSleep = "systemSleep"
    case focusMode = "focusMode"

    public var displayName: String {
        switch self {
        case .meeting: return "In Meeting"
        case .screenRecording: return "Screen Recording"
        case .fullscreen: return "Fullscreen App"
        case .idle: return "Away from Computer"
        case .manual: return "Manual Pause"
        case .quietHours: return "Quiet Hours"
        case .systemSleep: return "System Sleep"
        case .focusMode: return "Focus Mode"
        }
    }

    public var icon: String {
        switch self {
        case .meeting: return "video.fill"
        case .screenRecording: return "record.circle"
        case .fullscreen: return "rectangle.fill"
        case .idle: return "moon.zzz.fill"
        case .manual: return "pause.circle.fill"
        case .quietHours: return "moon.stars.fill"
        case .systemSleep: return "powersleep"
        case .focusMode: return "sparkles"
        }
    }
}

// MARK: - Pause Event

/// A single pause event with timing and context
public struct PauseEvent: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public var endTime: Date?
    public let reason: PauseReason
    public let relatedApp: String?

    public var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(timestamp)
    }

    public var durationMinutes: Int {
        Int(duration / 60)
    }

    public init(reason: PauseReason, relatedApp: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.endTime = nil
        self.reason = reason
        self.relatedApp = relatedApp
    }

    public mutating func complete() {
        self.endTime = Date()
    }
}

// NOTE: PauseEventSummary is defined in AdherenceManager.swift
// Using typealias to maintain compatibility
public typealias PauseEventSummaryStats = AdherenceManager.PauseEventSummary

// MARK: - Work Session

/// A complete work session from start to finish
public struct WorkSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public var breaksTaken: Int = 0
    public var breaksSkipped: Int = 0
    public var nudgesFollowed: Int = 0
    public var nudgesDismissed: Int = 0
    public var pauseEvents: [PauseEvent] = []

    public var isActive: Bool {
        endTime == nil
    }

    public var totalDurationSeconds: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime))
    }

    public var totalDurationMinutes: Int {
        totalDurationSeconds / 60
    }

    public var activeDurationSeconds: Int {
        let pauseTime = pauseEvents.reduce(0) { $0 + Int($1.duration) }
        return max(0, totalDurationSeconds - pauseTime)
    }

    public var averageBreakInterval: TimeInterval {
        guard breaksTaken > 0 else { return 0 }
        return TimeInterval(activeDurationSeconds) / TimeInterval(breaksTaken)
    }

    public var longestFocusStretch: TimeInterval {
        // Calculate based on break timestamps
        guard breaksTaken > 0 else { return TimeInterval(activeDurationSeconds) }
        return averageBreakInterval * 1.5  // Estimate
    }

    public var completionRate: Double {
        let total = breaksTaken + breaksSkipped
        guard total > 0 else { return 1.0 }
        return Double(breaksTaken) / Double(total)
    }

    public init() {
        self.id = UUID()
        self.startTime = Date()
    }

    public mutating func complete() {
        self.endTime = Date()
    }

    public mutating func recordBreak(completed: Bool) {
        if completed {
            breaksTaken += 1
        } else {
            breaksSkipped += 1
        }
    }

    public mutating func recordNudge(followed: Bool) {
        if followed {
            nudgesFollowed += 1
        } else {
            nudgesDismissed += 1
        }
    }

    public mutating func addPauseEvent(_ event: PauseEvent) {
        pauseEvents.append(event)
    }

    public mutating func completePauseEvent() {
        guard !pauseEvents.isEmpty else { return }
        pauseEvents[pauseEvents.count - 1].complete()
    }
}

// MARK: - Wellness Insight

/// Types of personalized wellness insights
public enum WellnessInsight: Codable, Identifiable, Equatable {
    case streakAchievement(days: Int)
    case improvingTrend(metric: String, percentage: Double)
    case decliningTrend(metric: String, percentage: Double)
    case peakProductivityTime(hour: Int)
    case longestStretchWarning(minutes: Int)
    case meetingHeavyDay(minutes: Int)
    case excellentBlinkCompliance
    case postureNeedsAttention
    case recommendedBreakInterval(minutes: Int)
    case goalAchieved(type: String)
    case consistentSchedule
    case improvedRecovery

    public var id: String {
        switch self {
        case .streakAchievement(let days): return "streak_\(days)"
        case .improvingTrend(let m, _): return "improving_\(m)"
        case .decliningTrend(let m, _): return "declining_\(m)"
        case .peakProductivityTime(let h): return "peak_\(h)"
        case .longestStretchWarning(let m): return "stretch_\(m)"
        case .meetingHeavyDay(let m): return "meeting_\(m)"
        case .excellentBlinkCompliance: return "blink_excellent"
        case .postureNeedsAttention: return "posture_attention"
        case .recommendedBreakInterval(let m): return "interval_\(m)"
        case .goalAchieved(let t): return "goal_\(t)"
        case .consistentSchedule: return "consistent"
        case .improvedRecovery: return "recovery"
        }
    }

    public var title: String {
        switch self {
        case .streakAchievement(let days):
            return "🔥 \(days) Day Streak!"
        case .improvingTrend(let metric, let pct):
            return "📈 \(metric) up \(Int(pct))%"
        case .decliningTrend(let metric, let pct):
            return "📉 \(metric) down \(Int(pct))%"
        case .peakProductivityTime(let hour):
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            if let date = Calendar.current.date(
                bySettingHour: hour, minute: 0, second: 0, of: Date())
            {
                return "⏰ Peak focus: \(formatter.string(from: date))"
            } else {
                return "⏰ Peak focus: \(hour):00"
            }
        case .longestStretchWarning(let minutes):
            return "⚠️ \(minutes) min without break"
        case .meetingHeavyDay(let minutes):
            return "📅 \(minutes) min in meetings today"
        case .excellentBlinkCompliance:
            return "👀 Excellent blink habits!"
        case .postureNeedsAttention:
            return "🪑 Posture needs attention"
        case .recommendedBreakInterval(let minutes):
            return "💡 Try \(minutes) min intervals"
        case .goalAchieved(let type):
            return "🎯 \(type) goal achieved!"
        case .consistentSchedule:
            return "📊 Consistent break schedule"
        case .improvedRecovery:
            return "✨ Better recovery this week"
        }
    }

    public var description: String {
        switch self {
        case .streakAchievement(let days):
            return "You've maintained good eye health for \(days) consecutive days."
        case .improvingTrend(let metric, let pct):
            return "Your \(metric.lowercased()) has improved by \(Int(pct))% compared to last week."
        case .decliningTrend(let metric, let pct):
            return
                "Your \(metric.lowercased()) has decreased by \(Int(pct))% compared to last week."
        case .peakProductivityTime(let hour):
            return "You take the most breaks around \(hour):00. This is when you're most focused!"
        case .longestStretchWarning(let minutes):
            return
                "You've been focused for \(minutes) minutes without a break. Consider shorter intervals."
        case .meetingHeavyDay:
            return "Heavy meeting day detected. Breaks are automatically paused during meetings."
        case .excellentBlinkCompliance:
            return "You're responding to 80%+ of blink reminders. Great for eye moisture!"
        case .postureNeedsAttention:
            return "Try responding to more posture reminders to reduce back strain."
        case .recommendedBreakInterval(let minutes):
            return "Based on your patterns, \(minutes)-minute work intervals may suit you better."
        case .goalAchieved(let type):
            return "Congratulations on reaching your \(type.lowercased()) goal today!"
        case .consistentSchedule:
            return "Your break times are consistent, which is great for building healthy habits."
        case .improvedRecovery:
            return "You're taking more complete breaks this week."
        }
    }

    public var icon: String {
        switch self {
        case .streakAchievement: return "flame.fill"
        case .improvingTrend: return "arrow.up.right"
        case .decliningTrend: return "arrow.down.right"
        case .peakProductivityTime: return "clock.fill"
        case .longestStretchWarning: return "exclamationmark.triangle.fill"
        case .meetingHeavyDay: return "calendar.badge.clock"
        case .excellentBlinkCompliance: return "eye.fill"
        case .postureNeedsAttention: return "figure.stand"
        case .recommendedBreakInterval: return "lightbulb.fill"
        case .goalAchieved: return "target"
        case .consistentSchedule: return "chart.bar.fill"
        case .improvedRecovery: return "sparkles"
        }
    }

    public var isPositive: Bool {
        switch self {
        case .streakAchievement, .improvingTrend, .peakProductivityTime,
            .excellentBlinkCompliance, .goalAchieved, .consistentSchedule, .improvedRecovery:
            return true
        case .decliningTrend, .longestStretchWarning, .meetingHeavyDay,
            .postureNeedsAttention, .recommendedBreakInterval:
            return false
        }
    }
}

// MARK: - Trend Direction

/// Direction of a trend
public enum TrendDirection: String, Codable {
    case improving
    case stable
    case declining

    public var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    public var displayText: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }
}

// MARK: - Period Summary

/// Aggregated statistics for a time period
public struct PeriodSummary: Codable {
    public var totalScreenTimeMinutes: Int = 0
    public var totalBreakTimeMinutes: Int = 0
    public var totalMeetingMinutes: Int = 0
    public var totalIdleMinutes: Int = 0
    public var breaksCompleted: Int = 0
    public var breaksSkipped: Int = 0
    public var avgDailyScore: Double = 100.0
    public var trend: TrendDirection = .stable
    public var comparisonToPrevious: Double = 0.0  // % change
    public var daysTracked: Int = 0

    public var breakCompletionRate: Double {
        let total = breaksCompleted + breaksSkipped
        guard total > 0 else { return 1.0 }
        return Double(breaksCompleted) / Double(total)
    }

    public var avgBreaksPerDay: Double {
        guard daysTracked > 0 else { return 0 }
        return Double(breaksCompleted) / Double(daysTracked)
    }

    public var avgScreenTimePerDay: Int {
        guard daysTracked > 0 else { return 0 }
        return totalScreenTimeMinutes / daysTracked
    }
}

// MARK: - Hourly Distribution

/// Tracks activity distribution by hour of day
public struct HourlyDistribution: Codable {
    public var breaks: [Int: Int] = [:]  // hour (0-23) -> count
    public var nudges: [Int: Int] = [:]
    public var pauses: [Int: Int] = [:]

    public init() {
        // Initialize all hours to 0
        for hour in 0..<24 {
            breaks[hour] = 0
            nudges[hour] = 0
            pauses[hour] = 0
        }
    }

    public mutating func recordBreak(at hour: Int) {
        breaks[hour, default: 0] += 1
    }

    public mutating func recordNudge(at hour: Int) {
        nudges[hour, default: 0] += 1
    }

    public mutating func recordPause(at hour: Int) {
        pauses[hour, default: 0] += 1
    }

    public var peakBreakHour: Int? {
        breaks.max(by: { $0.value < $1.value })?.key
    }

    public var peakActivityHours: [Int] {
        let sorted = breaks.sorted { $0.value > $1.value }
        return Array(sorted.prefix(3).map { $0.key })
    }
}

// MARK: - Statistics Engine

/// Core statistics engine for advanced analytics
@MainActor
public final class StatisticsEngine: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var currentSession: WorkSession?
    @Published public private(set) var todaysSessions: [WorkSession] = []
    @Published public private(set) var currentPauseEvent: PauseEvent?
    @Published public private(set) var insights: [WellnessInsight] = []

    // MARK: - Private Properties

    private let logger = Logger(
        subsystem: "com.kumargaurav.Sight.stats", category: "StatisticsEngine")
    private let persistenceQueue = DispatchQueue(
        label: "com.sight.stats.persistence", qos: .utility)

    // Lock for thread-safe session access
    private let sessionLock = NSLock()

    // MARK: - Singleton

    public static let shared = StatisticsEngine()

    // MARK: - Initialization

    public init() {
        loadPersistedData()
        checkDayRollover()
    }

    // MARK: - Session Management

    /// Start a new work session
    public func startSession() {
        guard currentSession == nil else {
            logger.warning("Session already active, ignoring start request")
            return
        }

        let session = WorkSession()
        currentSession = session
        logger.info("Started new work session: \(session.id)")
        persistSessions()
    }

    /// End the current work session
    public func endSession() {
        guard var session = currentSession else {
            logger.warning("No active session to end")
            return
        }

        session.complete()
        todaysSessions.append(session)
        currentSession = nil
        logger.info(
            "Ended work session: \(session.id), duration: \(session.totalDurationMinutes) min")
        persistSessions()
    }

    /// Record a break in the current session
    public func recordBreak(completed: Bool) {
        guard currentSession != nil else { return }
        currentSession?.recordBreak(completed: completed)

        // Sync screen time to AdherenceManager
        let screenTime = todayScreenTimeMinutes
        AdherenceManager.shared.recordScreenTime(minutes: screenTime)

        persistSessions()
    }

    /// Record a nudge response in the current session
    public func recordNudge(followed: Bool) {
        guard currentSession != nil else { return }
        currentSession?.recordNudge(followed: followed)
        persistSessions()
    }

    // MARK: - Pause Tracking

    /// Start a pause event
    public func startPause(reason: PauseReason, relatedApp: String? = nil) {
        guard currentPauseEvent == nil else {
            logger.warning("Pause already active, completing previous pause")
            endPause()
            return
        }

        let event = PauseEvent(reason: reason, relatedApp: relatedApp)
        currentPauseEvent = event
        currentSession?.addPauseEvent(event)
        logger.info("Started pause: \(reason.rawValue)")
    }

    /// End the current pause event
    public func endPause() {
        guard var pauseEvent = currentPauseEvent else { return }

        // Complete the pause event first to capture duration
        pauseEvent.complete()
        let durationMinutes = pauseEvent.durationMinutes
        let reason = pauseEvent.reason.rawValue

        // Update session's pause event
        currentSession?.completePauseEvent()

        logger.info("Ended pause: \(reason), duration: \(durationMinutes) min")
        currentPauseEvent = nil
        persistSessions()
    }

    // MARK: - Analytics

    /// Get today's total active screen time
    public var todayScreenTimeMinutes: Int {
        var total = todaysSessions.reduce(0) { $0 + $1.activeDurationSeconds }
        if let session = currentSession {
            total += session.activeDurationSeconds
        }
        return total / 60
    }

    /// Get today's total break time
    public var todayBreakTimeMinutes: Int {
        // This comes from AdherenceManager
        return AdherenceManager.shared.todayStats.totalBreakMinutes
    }

    /// Get session statistics for today
    public var todaySessionStats: (count: Int, avgDuration: Int, totalActive: Int) {
        let sessions = todaysSessions + (currentSession != nil ? [currentSession!] : [])
        let count = sessions.count
        let totalActive = sessions.reduce(0) { $0 + $1.activeDurationSeconds } / 60
        let avgDuration = count > 0 ? totalActive / count : 0
        return (count, avgDuration, totalActive)
    }

    /// Get pause breakdown for today
    public func todayPauseBreakdown() -> [PauseReason: (count: Int, minutes: Int)] {
        var breakdown: [PauseReason: (count: Int, minutes: Int)] = [:]

        let allPauses = (todaysSessions + (currentSession != nil ? [currentSession!] : []))
            .flatMap { $0.pauseEvents }

        for pause in allPauses {
            let current = breakdown[pause.reason] ?? (0, 0)
            breakdown[pause.reason] = (current.0 + 1, current.1 + pause.durationMinutes)
        }

        return breakdown
    }

    /// Get hourly break distribution for today
    public func todayHourlyDistribution() -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        for hour in 0..<24 {
            distribution[hour] = 0
        }

        // Get from AdherenceManager
        let hourlyData = AdherenceManager.shared.todayStats.hourlyBreakDistribution
        for (hour, count) in hourlyData {
            distribution[hour] = count
        }

        return distribution
    }

    // MARK: - Insights Generation

    /// Generate insights based on current data
    public func generateInsights() {
        var newInsights: [WellnessInsight] = []

        // Streak achievement
        let streak = AdherenceManager.shared.currentStreak
        if streak >= 3 {
            newInsights.append(.streakAchievement(days: streak))
        }

        // Check weekly trend with actual calculated percentage
        let summary = AdherenceManager.shared.getWeeklySummary()
        let previousWeekStats = AdherenceManager.shared.getPreviousWeekStats()
        let currentAvgScore = summary.averageScore
        let previousAvgScore = previousWeekStats.averageScore

        // Calculate actual percentage change
        let percentChange =
            previousAvgScore > 0
            ? abs((currentAvgScore - previousAvgScore) / previousAvgScore * 100)
            : 0

        switch summary.trend {
        case .improving:
            if percentChange > 1 {
                newInsights.append(
                    .improvingTrend(metric: "Break adherence", percentage: percentChange))
            }
        case .declining:
            if percentChange > 1 {
                newInsights.append(
                    .decliningTrend(metric: "Break adherence", percentage: percentChange))
            }
        case .stable:
            break
        }

        // Peak productivity time
        let distribution = todayHourlyDistribution()
        if let peakHour = distribution.max(by: { $0.value < $1.value })?.key,
            distribution[peakHour] ?? 0 > 0
        {
            newInsights.append(.peakProductivityTime(hour: peakHour))
        }

        // Meeting heavy day
        let meetingMinutes = AdherenceManager.shared.todayStats.totalMeetingMinutes
        if meetingMinutes > 120 {
            newInsights.append(.meetingHeavyDay(minutes: meetingMinutes))
        }

        // Blink compliance
        let todayStats = AdherenceManager.shared.todayStats
        if todayStats.blinkNudgesShown > 5 {
            let compliance =
                Double(todayStats.blinkNudgesFollowed) / Double(todayStats.blinkNudgesShown)
            if compliance >= 0.8 {
                newInsights.append(.excellentBlinkCompliance)
            }
        }

        // Posture attention
        if todayStats.postureNudgesShown > 3 {
            let compliance =
                Double(todayStats.postureNudgesFollowed) / Double(todayStats.postureNudgesShown)
            if compliance < 0.5 {
                newInsights.append(.postureNeedsAttention)
            }
        }

        // Goal achieved
        if AdherenceManager.shared.goalMet {
            newInsights.append(.goalAchieved(type: "Daily breaks"))
        }

        self.insights = newInsights

        logger.info("Generated \(newInsights.count) insights")
    }

    // MARK: - Persistence

    private func persistSessions() {
        // Capture data on main actor before dispatching to background
        let sessionsToSave = todaysSessions + (currentSession != nil ? [currentSession!] : [])

        persistenceQueue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(sessionsToSave)
                UserDefaults.standard.set(data, forKey: "TodayWorkSessions")
                UserDefaults.standard.set(Date(), forKey: "SessionsDate")
            } catch {
                self?.logger.error("Failed to persist sessions: \(error.localizedDescription)")
            }
        }
    }

    private func loadPersistedData() {
        guard let data = UserDefaults.standard.data(forKey: "TodayWorkSessions"),
            let sessions = try? JSONDecoder().decode([WorkSession].self, from: data)
        else {
            return
        }

        // Check if data is from today
        if let savedDate = UserDefaults.standard.object(forKey: "SessionsDate") as? Date,
            Calendar.current.isDateInToday(savedDate)
        {
            // Separate active and completed sessions
            todaysSessions = sessions.filter { !$0.isActive }
            if let active = sessions.first(where: { $0.isActive }) {
                currentSession = active
            }
            logger.info("Loaded \(sessions.count) sessions from today")
        } else {
            // Data is from previous day, clear it
            UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")
            logger.info("Cleared previous day's session data")
        }
    }

    private func checkDayRollover() {
        // First, check if we need to reset NOW (e.g., app launched on new day)
        if let lastResetDate = UserDefaults.standard.object(forKey: "StatsLastResetDate") as? Date {
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastResetDate) {
                logger.info("Day changed since last run, resetting daily data")
                resetDailyData()
            }
        }

        // Then schedule check at midnight (backup, may be cancelled on app suspend)
        scheduleMidnightReset()
    }

    private func scheduleMidnightReset() {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
            let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow)
        else {
            return
        }

        let interval = midnight.timeIntervalSinceNow

        DispatchQueue.main.asyncAfter(deadline: .now() + max(60, interval)) { [weak self] in
            self?.resetDailyData()
            self?.scheduleMidnightReset()
        }
    }

    private func resetDailyData() {
        // End any active session
        if currentSession != nil {
            endSession()
        }

        todaysSessions.removeAll()
        insights.removeAll()
        UserDefaults.standard.removeObject(forKey: "TodayWorkSessions")

        // Track when we reset to detect day changes on next launch
        UserDefaults.standard.set(Date(), forKey: "StatsLastResetDate")

        logger.info("Daily session data reset")
    }
}
