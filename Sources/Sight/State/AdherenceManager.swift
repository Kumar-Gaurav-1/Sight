import AppKit
import Combine
import Foundation
import os.log

/// Tracks user adherence to wellness goals and manages incentives
/// Implements game-theory logic: "Skipping is allowed but costly"
public final class AdherenceManager: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var weeklyScore: Double = 100.0  // 0-100
    @Published public private(set) var currentStreak: Int = 0  // Days
    @Published public private(set) var strainPenalty: Double = 0.0  // 0.0-1.0
    @Published public private(set) var todayStats: DayStats = DayStats(
        date: Calendar.current.startOfDay(for: Date()))

    // MARK: - Types

    public struct DayStats: Codable {
        var date: Date
        var breaksCompleted: Int = 0
        var breaksSkipped: Int = 0
        var nudgesFollowed: Int = 0
        var nudgesSnoozed: Int = 0
        var totalBreakMinutes: Int = 0

        // Granular stats
        var shortBreaksCompleted: Int = 0
        var longBreaksCompleted: Int = 0

        // Enhanced tracking - Nudge analytics
        var blinkNudgesShown: Int = 0
        var blinkNudgesFollowed: Int = 0
        var postureNudgesShown: Int = 0
        var postureNudgesFollowed: Int = 0

        // Time tracking
        var totalScreenTimeMinutes: Int = 0
        var totalMeetingMinutes: Int = 0
        var totalIdleMinutes: Int = 0
        var longestSessionMinutes: Int = 0

        // Pause breakdown
        var pauseEvents: [PauseEventSummary] = []

        // Hourly break distribution (hour 0-23 -> break count)
        var hourlyBreakDistribution: [Int: Int] = [:]

        // Legacy daily score (break-focused)
        var dailyScore: Double {
            let totalEvents = Double(
                breaksCompleted + breaksSkipped + nudgesFollowed + nudgesSnoozed)
            guard totalEvents > 0 else { return 100.0 }

            let successful = Double(breaksCompleted + nudgesFollowed)
            // Snoozes count as 50% success (intention to do it later)
            // Skips are 0%
            let partial = Double(nudgesSnoozed) * 0.5

            return min(100.0, ((successful + partial) / totalEvents) * 100.0)
        }

        // Enhanced wellness score considering all factors
        // Weights: breaks 40%, nudges 30%, session balance 20%, recovery 10%
        var wellnessScore: Double {
            let breakScore = calculateBreakScore()
            let nudgeScore = calculateNudgeScore()
            let sessionScore = calculateSessionScore()
            let recoveryScore = calculateRecoveryScore()
            return breakScore * 0.4 + nudgeScore * 0.3 + sessionScore * 0.2 + recoveryScore * 0.1
        }

        // Break adherence score (0-100)
        private func calculateBreakScore() -> Double {
            let totalBreaks = breaksCompleted + breaksSkipped
            guard totalBreaks > 0 else { return 100.0 }
            return (Double(breaksCompleted) / Double(totalBreaks)) * 100.0
        }

        // Nudge compliance score (0-100)
        private func calculateNudgeScore() -> Double {
            let totalBlinks = blinkNudgesShown
            let totalPosture = postureNudgesShown
            let totalNudges = totalBlinks + totalPosture
            guard totalNudges > 0 else { return 100.0 }

            let followed = blinkNudgesFollowed + postureNudgesFollowed
            return (Double(followed) / Double(totalNudges)) * 100.0
        }

        // Session balance score - penalizes very long unbroken sessions
        private func calculateSessionScore() -> Double {
            // Ideal: no session longer than 25 minutes
            // Perfect score if longestSession <= 25 min
            // Decreases linearly up to 60 min (score = 50)
            // Below 50 after 60 min
            guard longestSessionMinutes > 0 else { return 100.0 }

            if longestSessionMinutes <= 25 {
                return 100.0
            } else if longestSessionMinutes <= 60 {
                // Linear decrease from 100 to 50 between 25-60 min
                let excess = Double(longestSessionMinutes - 25)
                return 100.0 - (excess / 35.0 * 50.0)
            } else {
                // Below 50 for sessions over 60 min
                let excess = Double(longestSessionMinutes - 60)
                return max(10.0, 50.0 - (excess / 30.0 * 20.0))
            }
        }

        // Recovery score - ratio of break time to screen time
        private func calculateRecoveryScore() -> Double {
            guard totalScreenTimeMinutes > 0 else { return 100.0 }

            // Ideal ratio: 5 min break per 25 min screen time = 20%
            // Score 100 for 20%+ recovery ratio
            let ratio = Double(totalBreakMinutes) / Double(totalScreenTimeMinutes)
            if ratio >= 0.2 {
                return 100.0
            } else if ratio >= 0.1 {
                // Linear decrease from 100 to 60 between 20%-10%
                return 60.0 + (ratio - 0.1) / 0.1 * 40.0
            } else {
                // Below 60 for less than 10% recovery
                return max(20.0, ratio / 0.1 * 60.0)
            }
        }

        // Blink nudge compliance percentage
        var blinkCompliance: Double {
            guard blinkNudgesShown > 0 else { return 1.0 }
            return Double(blinkNudgesFollowed) / Double(blinkNudgesShown)
        }

        // Posture nudge compliance percentage
        var postureCompliance: Double {
            guard postureNudgesShown > 0 else { return 1.0 }
            return Double(postureNudgesFollowed) / Double(postureNudgesShown)
        }
    }

    // MARK: - Pause Event Summary (for daily aggregation)

    public struct PauseEventSummary: Codable {
        public var reason: String
        public var count: Int
        public var totalMinutes: Int

        public init(reason: String, count: Int = 0, totalMinutes: Int = 0) {
            self.reason = reason
            self.count = count
            self.totalMinutes = totalMinutes
        }
    }

    // MARK: - Properties

    private var stats: [DayStats] = []
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.adherence", category: "Adherence")

    // SECURITY: Serial queue for thread-safe stats access
    private let statsQueue = DispatchQueue(label: "com.sight.adherence.stats", qos: .utility)

    // Game Theory Constants
    private let skipCost: Double = 0.15  // 15% strain increase per skip
    private let breakReward: Double = 0.20  // 20% strain reduction per break

    // MARK: - Singleton

    public static let shared = AdherenceManager()

    // Timer for periodic sync
    private var syncTimer: Timer?

    // MARK: - Initialization

    init() {
        // Initialize goal from saved value or default to 6 breaks per day
        self.dailyBreakGoal =
            UserDefaults.standard.object(forKey: "AdherenceDailyGoal") as? Int ?? 6
        loadStats()
        checkStreak()
        startPeriodicSync()

        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Sync Methods

    /// Start periodic sync (every 30 seconds)
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.forceRefresh()
        }
    }

    /// Force refresh stats from storage and update UI
    public func forceRefresh() {
        // Reload from storage
        loadStats()

        // Force UI update
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
        logger.debug("Stats force refreshed")
    }

    @objc private func appBecameActive() {
        forceRefresh()
    }

    // MARK: - API

    public func recordBreak(completed: Bool, duration: Int) {
        var today = getTodayStats()

        logger.info(
            "recordBreak called: completed=\(completed), duration=\(duration)s, current breaks=\(today.breaksCompleted)"
        )

        if completed {
            today.breaksCompleted += 1
            today.totalBreakMinutes += max(1, duration / 60)

            // Categorize break type
            if duration <= 180 {  // Under 3 minutes = Short
                today.shortBreaksCompleted += 1
            } else {  // Over 3 minutes = Long
                today.longBreaksCompleted += 1
            }

            // Track hourly distribution
            let hour = Calendar.current.component(.hour, from: Date())
            today.hourlyBreakDistribution[hour, default: 0] += 1

            reduceStrain()
            logger.info(
                "Break recorded: total breaks now=\(today.breaksCompleted), minutes=\(today.totalBreakMinutes)"
            )
        } else {
            today.breaksSkipped += 1
            applySkipPenalty()
            logger.info("Break skipped: total skipped=\(today.breaksSkipped)")
        }

        saveStats(today)
    }

    public func recordNudge(action: NudgeAction) {
        var today = getTodayStats()

        switch action {
        case .followed:
            today.nudgesFollowed += 1
            // Small strain relief for nudges
            strainPenalty = max(0.0, strainPenalty - 0.05)
        case .snoozed:
            today.nudgesSnoozed += 1
            // Small penalty for snooze
            strainPenalty = min(1.0, strainPenalty + 0.02)
        case .dismissed:
            // Neutral? Or count as skipped?
            // Assuming dismissed without doing it -> Skipped
            today.nudgesSnoozed += 1  // Treat as snooze for stats for now
        }

        saveStats(today)
    }

    public enum NudgeAction {
        case followed
        case snoozed
        case dismissed
    }

    // MARK: - Enhanced Tracking API

    /// Record a blink nudge event
    /// - Parameters:
    ///   - shown: Whether the nudge was shown (true) or this is a follow-up (false)
    ///   - followed: Whether the user followed the nudge
    public func recordBlinkNudge(shown: Bool, followed: Bool) {
        var today = getTodayStats()
        if shown {
            today.blinkNudgesShown += 1
        }
        if followed {
            today.blinkNudgesFollowed += 1
        }
        saveStats(today)
        logger.debug("Blink nudge recorded: shown=\(shown), followed=\(followed)")
    }

    /// Record a posture nudge event
    /// - Parameters:
    ///   - shown: Whether the nudge was shown (true) or this is a follow-up (false)
    ///   - followed: Whether the user followed the nudge
    public func recordPostureNudge(shown: Bool, followed: Bool) {
        var today = getTodayStats()
        if shown {
            today.postureNudgesShown += 1
        }
        if followed {
            today.postureNudgesFollowed += 1
        }
        saveStats(today)
        logger.debug("Posture nudge recorded: shown=\(shown), followed=\(followed)")
    }

    /// Record active screen time
    /// - Parameter minutes: Number of minutes of active screen time to add
    public func recordActiveTime(minutes: Int) {
        var today = getTodayStats()
        today.totalScreenTimeMinutes += minutes
        saveStats(today)
    }

    /// Record meeting time
    /// - Parameter minutes: Number of minutes spent in meeting
    public func recordMeetingTime(minutes: Int) {
        var today = getTodayStats()
        today.totalMeetingMinutes += minutes
        saveStats(today)
    }

    /// Record idle time
    /// - Parameter minutes: Number of minutes spent idle
    public func recordIdleTime(minutes: Int) {
        var today = getTodayStats()
        today.totalIdleMinutes += minutes
        saveStats(today)
    }

    /// Record screen time (active work time)
    /// - Parameter minutes: Number of minutes of active screen time
    public func recordScreenTime(minutes: Int) {
        var today = getTodayStats()
        today.totalScreenTimeMinutes = minutes  // Set to cumulative session time
        saveStats(today)
    }

    /// Record a pause event
    /// - Parameters:
    ///   - reason: The reason for the pause
    ///   - duration: Duration in seconds
    public func recordPause(reason: PauseReason, duration: TimeInterval) {
        var today = getTodayStats()
        let durationMinutes = Int(duration / 60)

        // Update or add pause summary
        if let index = today.pauseEvents.firstIndex(where: { $0.reason == reason.rawValue }) {
            today.pauseEvents[index].count += 1
            today.pauseEvents[index].totalMinutes += durationMinutes
        } else {
            today.pauseEvents.append(
                PauseEventSummary(
                    reason: reason.rawValue,
                    count: 1,
                    totalMinutes: durationMinutes
                ))
        }

        // Track meeting time specifically
        if reason == .meeting {
            today.totalMeetingMinutes += durationMinutes
        }

        saveStats(today)
        logger.debug("Pause recorded: \(reason.rawValue), \(durationMinutes) min")
    }

    /// Update the longest session duration for today
    /// - Parameter minutes: Session duration in minutes
    public func updateLongestSession(minutes: Int) {
        var today = getTodayStats()
        if minutes > today.longestSessionMinutes {
            today.longestSessionMinutes = minutes
            saveStats(today)
        }
    }

    /// Record a break at the current hour (for hourly distribution tracking)
    private func recordBreakHour() {
        var today = getTodayStats()
        let hour = Calendar.current.component(.hour, from: Date())
        today.hourlyBreakDistribution[hour, default: 0] += 1
        saveStats(today)
    }

    /// Get hourly break distribution for a period
    public func getHourlyDistribution(for period: StatsPeriod) -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        for hour in 0..<24 {
            distribution[hour] = 0
        }

        let filteredStats: [DayStats]
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .today:
            filteredStats = [todayStats]
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            filteredStats = stats.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            filteredStats = stats.filter { $0.date >= monthAgo }
        case .all:
            filteredStats = stats
        }

        for day in filteredStats {
            for (hour, count) in day.hourlyBreakDistribution {
                distribution[hour, default: 0] += count
            }
        }

        return distribution
    }

    /// Get the peak productivity hour (most breaks taken)
    public func getPeakProductivityHour() -> Int? {
        let distribution = getHourlyDistribution(for: .week)
        return distribution.max(by: { $0.value < $1.value })?.key
    }

    /// Get average session duration
    public func getAverageSessionDuration() -> TimeInterval {
        let recentStats = getDailyStats(days: 7)
        let sessions = recentStats.filter { $0.longestSessionMinutes > 0 }
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.longestSessionMinutes }
        return TimeInterval(total / sessions.count * 60)
    }

    /// Get previous week's stats for comparison
    public func getPreviousWeekStats() -> AggregatedStats {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let filteredStats = stats.filter { $0.date >= twoWeeksAgo && $0.date < weekAgo }

        guard !filteredStats.isEmpty else {
            return AggregatedStats()
        }

        var result = AggregatedStats()
        for day in filteredStats {
            result.breaksCompleted += day.breaksCompleted
            result.breaksSkipped += day.breaksSkipped
            result.totalBreakMinutes += day.totalBreakMinutes
            result.shortBreaksCompleted += day.shortBreaksCompleted
            result.longBreaksCompleted += day.longBreaksCompleted
        }

        result.daysTracked = filteredStats.count
        result.averageScore =
            filteredStats.reduce(0.0) { $0 + $1.dailyScore } / Double(filteredStats.count)

        return result
    }

    // MARK: - Statistics Period

    public enum StatsPeriod: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All"
    }

    public struct AggregatedStats {
        public var breaksCompleted: Int = 0
        public var breaksSkipped: Int = 0
        public var totalBreakMinutes: Int = 0
        public var shortBreaksCompleted: Int = 0
        public var longBreaksCompleted: Int = 0
        public var averageScore: Double = 100.0
        public var daysTracked: Int = 0
    }

    // MARK: - Goals

    @Published public var dailyBreakGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyBreakGoal, forKey: "AdherenceDailyGoal")
        }
    }

    /// Progress toward daily goal (0.0 - 1.0+)
    public var goalProgress: Double {
        guard dailyBreakGoal > 0 else { return 1.0 }
        return Double(todayStats.breaksCompleted) / Double(dailyBreakGoal)
    }

    /// Whether daily goal has been met
    public var goalMet: Bool {
        todayStats.breaksCompleted >= dailyBreakGoal
    }

    /// Total breaks completed across all tracked days
    public var totalBreaksCompleted: Int {
        stats.reduce(0) { $0 + $1.breaksCompleted }
    }

    // MARK: - Weekly Summary

    public struct WeeklySummary {
        public var totalBreaks: Int
        public var totalMinutes: Int
        public var averageScore: Double
        public var bestDay: String
        public var streak: Int
        public var trend: Trend
    }

    public enum Trend: String {
        case improving = "↑ Improving"
        case stable = "→ Stable"
        case declining = "↓ Declining"
    }

    /// Generate a weekly summary
    public func getWeeklySummary() -> WeeklySummary {
        let calendar = Calendar.current
        let now = Date()

        // This week's stats - include todayStats to ensure current day is counted
        let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        var thisWeekStats = stats.filter { $0.date >= thisWeekStart }

        // Add todayStats if not already in the list (it may not be saved yet)
        let todayIsIncluded = thisWeekStats.contains {
            calendar.isDate($0.date, inSameDayAs: Date())
        }
        if !todayIsIncluded {
            thisWeekStats.append(todayStats)
        }

        // Last week's stats (for trend)
        let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let lastWeekStats = stats.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }

        // Calculate metrics
        let totalBreaks = thisWeekStats.reduce(0) { $0 + $1.breaksCompleted }
        let totalMinutes = thisWeekStats.reduce(0) { $0 + $1.totalBreakMinutes }
        let avgScore =
            thisWeekStats.isEmpty
            ? 100.0 : thisWeekStats.reduce(0.0) { $0 + $1.dailyScore } / Double(thisWeekStats.count)

        // Find best day
        let bestDayStats = thisWeekStats.max(by: { $0.dailyScore < $1.dailyScore })
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let bestDayName = bestDayStats.map { dayFormatter.string(from: $0.date) } ?? "N/A"

        // Calculate trend
        let lastWeekAvg =
            lastWeekStats.isEmpty
            ? 100.0 : lastWeekStats.reduce(0.0) { $0 + $1.dailyScore } / Double(lastWeekStats.count)
        let trend: Trend
        if avgScore > lastWeekAvg + 5 {
            trend = .improving
        } else if avgScore < lastWeekAvg - 5 {
            trend = .declining
        } else {
            trend = .stable
        }

        return WeeklySummary(
            totalBreaks: totalBreaks,
            totalMinutes: totalMinutes,
            averageScore: avgScore,
            bestDay: bestDayName,
            streak: currentStreak,
            trend: trend
        )
    }

    /// Get aggregated statistics for a given period
    public func getAggregatedStats(for period: StatsPeriod) -> AggregatedStats {
        let calendar = Calendar.current
        let now = Date()
        let filteredStats: [DayStats]

        switch period {
        case .today:
            filteredStats = [todayStats]
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            filteredStats = stats.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            filteredStats = stats.filter { $0.date >= monthAgo }
        case .all:
            filteredStats = stats
        }

        guard !filteredStats.isEmpty else {
            return AggregatedStats()
        }

        var result = AggregatedStats()
        for day in filteredStats {
            result.breaksCompleted += day.breaksCompleted
            result.breaksSkipped += day.breaksSkipped
            result.totalBreakMinutes += day.totalBreakMinutes
            result.shortBreaksCompleted += day.shortBreaksCompleted
            result.longBreaksCompleted += day.longBreaksCompleted
        }

        result.daysTracked = filteredStats.count
        result.averageScore =
            filteredStats.reduce(0.0) { $0 + $1.dailyScore } / Double(filteredStats.count)

        return result
    }

    /// Get daily stats for the last N days (for charts)
    public func getDailyStats(days: Int) -> [DayStats] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        return stats.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }

    /// Reset all statistics
    public func resetAllStats() {
        stats.removeAll()
        todayStats = DayStats(date: Date())
        strainPenalty = 0.0
        currentStreak = 0
        weeklyScore = 100.0
        UserDefaults.standard.removeObject(forKey: "AdherenceStats")
        logger.info("All statistics reset")
    }

    // MARK: - Export

    /// Export all statistics as JSON
    public func exportAsJSON() -> Data? {
        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "version": 1,
            "summary": [
                "totalDays": stats.count,
                "currentStreak": currentStreak,
                "weeklyScore": weeklyScore,
            ],
            "days": stats.map { day -> [String: Any] in
                [
                    "date": ISO8601DateFormatter().string(from: day.date),
                    "breaksCompleted": day.breaksCompleted,
                    "breaksSkipped": day.breaksSkipped,
                    "nudgesFollowed": day.nudgesFollowed,
                    "nudgesSnoozed": day.nudgesSnoozed,
                    "totalBreakMinutes": day.totalBreakMinutes,
                    "shortBreaksCompleted": day.shortBreaksCompleted,
                    "longBreaksCompleted": day.longBreaksCompleted,
                    "dailyScore": day.dailyScore,
                    "wellnessScore": day.wellnessScore,
                    // Enhanced fields
                    "blinkNudgesShown": day.blinkNudgesShown,
                    "blinkNudgesFollowed": day.blinkNudgesFollowed,
                    "postureNudgesShown": day.postureNudgesShown,
                    "postureNudgesFollowed": day.postureNudgesFollowed,
                    "totalScreenTimeMinutes": day.totalScreenTimeMinutes,
                    "longestSessionMinutes": day.longestSessionMinutes,
                ]
            },
        ]

        return try? JSONSerialization.data(
            withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
    }

    /// Export all statistics as CSV
    public func exportAsCSV() -> String {
        var csv =
            "Date,Breaks Completed,Breaks Skipped,Nudges Followed,Nudges Snoozed,Break Minutes,Short Breaks,Long Breaks,Daily Score\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for day in stats.sorted(by: { $0.date < $1.date }) {
            csv += "\(dateFormatter.string(from: day.date)),"
            csv += "\(day.breaksCompleted),"
            csv += "\(day.breaksSkipped),"
            csv += "\(day.nudgesFollowed),"
            csv += "\(day.nudgesSnoozed),"
            csv += "\(day.totalBreakMinutes),"
            csv += "\(day.shortBreaksCompleted),"
            csv += "\(day.longBreaksCompleted),"
            csv += String(format: "%.1f", day.dailyScore)
            csv += "\n"
        }

        return csv
    }

    // MARK: - Game Theory: Strain & Penalty

    private func applySkipPenalty() {
        // Skipping increases strain. High strain = harder to skip next time?
        // Or deeper consequences (escalation).
        strainPenalty = min(1.0, strainPenalty + skipCost)
        logger.info("Skip penalty applied. Current strain: \(self.strainPenalty)")
    }

    private func reduceStrain() {
        strainPenalty = max(0.0, strainPenalty - breakReward)
        logger.info("Strain reduced. Current strain: \(self.strainPenalty)")
    }

    // MARK: - Persistence

    private func getTodayStats() -> DayStats {
        // SECURITY: Thread-safe read with sync
        return statsQueue.sync {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            if let existing = stats.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                return existing
            }

            return DayStats(date: today)
        }
    }

    private func saveStats(_ day: DayStats) {
        // Use statsQueue for thread-safe access (same as getTodayStats)
        statsQueue.sync {
            self.stats.removeAll { Calendar.current.isDate($0.date, inSameDayAs: day.date) }
            self.stats.append(day)
        }

        // Update published property SYNCHRONOUSLY on main thread (critical for SwiftUI)
        if Thread.isMainThread {
            self.todayStats = day
            self.objectWillChange.send()
        } else {
            DispatchQueue.main.sync {
                self.todayStats = day
                self.objectWillChange.send()
            }
        }

        // Persist to UserDefaults
        let statsCopy = statsQueue.sync { self.stats }
        if let data = try? JSONEncoder().encode(statsCopy) {
            UserDefaults.standard.set(data, forKey: "AdherenceStats")
        }

        // Update aggregates (on main thread)
        if Thread.isMainThread {
            self.updateAggregates()
        } else {
            DispatchQueue.main.async {
                self.updateAggregates()
            }
        }

        logger.info("Stats saved: breaks=\(day.breaksCompleted), minutes=\(day.totalBreakMinutes)")
    }

    private func loadStats() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "AdherenceStats"),
            let loaded = try? JSONDecoder().decode([DayStats].self, from: data)
        {
            // Use statsQueue for thread-safe write
            statsQueue.sync {
                self.stats = loaded
            }

            // Populate todayStats if exists
            let calendar = Calendar.current
            if let today = loaded.first(where: { calendar.isDate($0.date, inSameDayAs: Date()) }) {
                self.todayStats = today
                logger.info(
                    "Loaded today's stats: breaks=\(today.breaksCompleted), minutes=\(today.totalBreakMinutes)"
                )
            } else {
                logger.info("No stats for today found, starting fresh")
            }
            self.updateAggregates()
        } else {
            logger.info("No persisted stats found")
        }
    }

    private func updateAggregates() {
        // SECURITY: Thread-safe read of stats array
        let statsCopy = statsQueue.sync { self.stats }

        // Calculate weekly score (last 7 days rolling average)
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let recentStats = statsCopy.filter { $0.date >= sevenDaysAgo }

        if recentStats.isEmpty {
            weeklyScore = 100.0
        } else {
            let totalScore = recentStats.reduce(0.0) { $0 + $1.dailyScore }
            weeklyScore = totalScore / Double(recentStats.count)
        }

        // Also update streak
        checkStreak()
    }

    private func checkStreak() {
        // SECURITY: Thread-safe read of stats array
        let statsCopy = statsQueue.sync { self.stats }

        // Calculate consecutive days with score >= 80% going backwards from today
        let calendar = Calendar.current
        let sortedStats = statsCopy.sorted { $0.date > $1.date }  // Most recent first

        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for day in sortedStats {
            let dayStart = calendar.startOfDay(for: day.date)

            // Check if this is the expected date (consecutive)
            if !calendar.isDate(dayStart, inSameDayAs: expectedDate) {
                // Gap in days - streak is broken
                break
            }

            // Check adherence threshold (80%)
            if day.dailyScore >= 80.0 {
                streak += 1
                // Move to previous day
                expectedDate =
                    calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                // Score too low - streak is broken
                break
            }
        }

        currentStreak = streak
        logger.info("Streak calculated: \(streak) days")
    }

    // MARK: - Data Export

    /// Export all stats to JSON format
    public func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            return try encoder.encode(stats)
        } catch {
            logger.error("Failed to export JSON: \(error.localizedDescription)")
            return nil
        }
    }

    /// Export all stats to CSV format
    public func exportToCSV() -> String {
        var csv =
            "Date,Breaks Completed,Breaks Skipped,Nudges Followed,Nudges Snoozed,Total Minutes,Daily Score\n"

        let formatter = ISO8601DateFormatter()

        for day in stats.sorted(by: { $0.date < $1.date }) {
            let line =
                "\(formatter.string(from: day.date)),\(day.breaksCompleted),\(day.breaksSkipped),\(day.nudgesFollowed),\(day.nudgesSnoozed),\(day.totalBreakMinutes),\(String(format: "%.1f", day.dailyScore))\n"
            csv += line
        }

        return csv
    }

    /// Save export to file and return URL
    /// SECURITY: Uses app-specific subdirectory to avoid polluting Documents folder
    public func saveExport(format: ExportFormat) -> URL? {
        let fileManager = FileManager.default
        guard
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            return nil
        }

        // Use app-specific subdirectory to avoid polluting Documents and filename collisions
        let sightExportsURL = documentsURL.appendingPathComponent(
            "Sight/exports", isDirectory: true)

        // Create directory if it doesn't exist
        do {
            try fileManager.createDirectory(
                at: sightExportsURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.error("Failed to create exports directory: \(error.localizedDescription)")
            return nil
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")

        let filename: String
        let data: Data

        switch format {
        case .json:
            filename = "sight_export_\(timestamp).json"
            guard let jsonData = exportToJSON() else { return nil }
            data = jsonData
        case .csv:
            filename = "sight_export_\(timestamp).csv"
            data = exportToCSV().data(using: .utf8) ?? Data()
        }

        let fileURL = sightExportsURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            logger.info("Exported data to \(fileURL.path)")
            return fileURL
        } catch {
            logger.error("Failed to save export: \(error.localizedDescription)")
            return nil
        }
    }

    public enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
}
