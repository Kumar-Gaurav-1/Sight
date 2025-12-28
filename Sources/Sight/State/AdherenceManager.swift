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
    @Published public private(set) var todayStats: DayStats = DayStats(date: Date())

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
    }

    // MARK: - Properties

    private var stats: [DayStats] = []
    private let logger = Logger(subsystem: "com.sight.adherence", category: "Adherence")

    // SECURITY: Serial queue for thread-safe stats access
    private let statsQueue = DispatchQueue(label: "com.sight.adherence.stats", qos: .utility)

    // Game Theory Constants
    private let skipCost: Double = 0.15  // 15% strain increase per skip
    private let breakReward: Double = 0.20  // 20% strain reduction per break

    // MARK: - Singleton

    public static let shared = AdherenceManager()

    // MARK: - Initialization

    init() {
        // Initialize goal from saved value or default to 6 breaks per day
        self.dailyBreakGoal =
            UserDefaults.standard.object(forKey: "AdherenceDailyGoal") as? Int ?? 6
        loadStats()
        checkStreak()
    }

    // MARK: - API

    public func recordBreak(completed: Bool, duration: Int) {
        var today = getTodayStats()

        if completed {
            today.breaksCompleted += 1
            today.totalBreakMinutes += max(1, duration / 60)

            // Categorize break type
            if duration <= 180 {  // Under 3 minutes = Short
                today.shortBreaksCompleted += 1
            } else {  // Over 3 minutes = Long
                today.longBreaksCompleted += 1
            }

            reduceStrain()
        } else {
            today.breaksSkipped += 1
            applySkipPenalty()
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

        // This week's stats
        let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        let thisWeekStats = stats.filter { $0.date >= thisWeekStart }

        // Last week's stats (for trend)
        let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: now)!
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
        // SECURITY: Thread-safe write with async on serial queue
        statsQueue.async { [weak self] in
            guard let self = self else { return }

            // Update list (now protected by serial queue)
            self.stats.removeAll { Calendar.current.isDate($0.date, inSameDayAs: day.date) }
            self.stats.append(day)

            // Persist
            let data = try? JSONEncoder().encode(self.stats)

            // Switch to main thread for UI updates
            DispatchQueue.main.async {
                // Update published property (triggers SwiftUI update)
                self.todayStats = day

                // Explicitly notify observers
                self.objectWillChange.send()

                // Save to UserDefaults on main thread (consistent with read)
                if let data = data {
                    UserDefaults.standard.set(data, forKey: "AdherenceStats")
                }

                // Update aggregates
                self.updateAggregates()
            }
        }
    }

    private func loadStats() {
        // SECURITY: Load on stats queue for thread safety
        statsQueue.async { [weak self] in
            guard let self = self else { return }

            if let data = UserDefaults.standard.data(forKey: "AdherenceStats"),
                let loaded = try? JSONDecoder().decode([DayStats].self, from: data)
            {
                self.stats = loaded

                // Populate todayStats if exists
                let calendar = Calendar.current
                let today = loaded.first(where: { calendar.isDate($0.date, inSameDayAs: Date()) })

                DispatchQueue.main.async {
                    if let today = today {
                        self.todayStats = today
                    }
                    self.updateAggregates()
                }
            }
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
