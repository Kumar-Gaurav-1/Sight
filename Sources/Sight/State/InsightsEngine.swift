import Foundation
import os.log

// MARK: - Insights Engine

/// Generates personalized wellness insights based on user behavior patterns
public final class InsightsEngine {

    // MARK: - Types

    /// Pattern detection thresholds
    private struct Thresholds {
        static let streakMinDays = 3
        static let excellentCompliance = 0.8  // 80%
        static let poorCompliance = 0.5  // 50%
        static let longSessionMinutes = 45
        static let heavyMeetingMinutes = 120
        static let significantTrendChange = 10.0  // 10%
        static let consistentTimeVariance = 30  // 30 minute variance is "consistent"
    }

    // MARK: - Properties

    private let logger = Logger(
        subsystem: "com.kumargaurav.Sight.insights", category: "InsightsEngine")

    // MARK: - Singleton

    public static let shared = InsightsEngine()

    public init() {}

    // MARK: - Main API

    /// Generate all applicable insights from current data
    public func generateInsights() -> [WellnessInsight] {
        var insights: [WellnessInsight] = []
        let adherence = AdherenceManager.shared

        // Streak achievements
        if let streakInsight = checkStreakAchievement() {
            insights.append(streakInsight)
        }

        // Trend analysis
        insights.append(contentsOf: analyzeTrends())

        // Peak productivity
        if let peakInsight = analyzePeakProductivity() {
            insights.append(peakInsight)
        }

        // Nudge compliance
        insights.append(contentsOf: analyzeNudgeCompliance())

        // Session balance
        if let sessionInsight = analyzeSessionBalance() {
            insights.append(sessionInsight)
        }

        // Meeting analysis
        if let meetingInsight = analyzeMeetingLoad() {
            insights.append(meetingInsight)
        }

        // Goal achievement
        if adherence.goalMet {
            insights.append(.goalAchieved(type: "Daily breaks"))
        }

        // Schedule consistency
        if let consistencyInsight = analyzeScheduleConsistency() {
            insights.append(consistencyInsight)
        }

        // Recovery improvement
        if let recoveryInsight = analyzeRecovery() {
            insights.append(recoveryInsight)
        }

        // Recommended break interval
        if let intervalInsight = recommendBreakInterval() {
            insights.append(intervalInsight)
        }

        logger.info("Generated \(insights.count) wellness insights")
        return insights
    }

    // MARK: - Pattern Detection

    /// Check for streak achievements
    private func checkStreakAchievement() -> WellnessInsight? {
        let streak = AdherenceManager.shared.currentStreak
        guard streak >= Thresholds.streakMinDays else { return nil }
        return .streakAchievement(days: streak)
    }

    /// Analyze trends compared to previous week
    private func analyzeTrends() -> [WellnessInsight] {
        var insights: [WellnessInsight] = []
        let adherence = AdherenceManager.shared

        let currentWeek = adherence.getAggregatedStats(for: .week)
        let previousWeek = adherence.getPreviousWeekStats()

        guard previousWeek.daysTracked > 0 else { return insights }

        // Compare break completion rates
        let currentRate =
            currentWeek.daysTracked > 0
            ? Double(currentWeek.breaksCompleted) / Double(max(1, currentWeek.daysTracked))
            : 0
        let previousRate =
            Double(previousWeek.breaksCompleted) / Double(max(1, previousWeek.daysTracked))

        if previousRate > 0 {
            let changePercent = ((currentRate - previousRate) / previousRate) * 100

            if changePercent >= Thresholds.significantTrendChange {
                insights.append(
                    .improvingTrend(metric: "Break adherence", percentage: changePercent))
            } else if changePercent <= -Thresholds.significantTrendChange {
                insights.append(
                    .decliningTrend(metric: "Break adherence", percentage: abs(changePercent)))
            }
        }

        // Compare scores
        if previousWeek.averageScore > 0 {
            let scoreChange = currentWeek.averageScore - previousWeek.averageScore
            if scoreChange >= Thresholds.significantTrendChange {
                insights.append(.improvingTrend(metric: "Wellness score", percentage: scoreChange))
            }
        }

        return insights
    }

    /// Analyze peak productivity times
    private func analyzePeakProductivity() -> WellnessInsight? {
        let distribution = AdherenceManager.shared.getHourlyDistribution(for: .week)

        // Find hour with most breaks (indicates high productivity/activity)
        guard let peakHour = distribution.max(by: { $0.value < $1.value }),
            peakHour.value > 0
        else {
            return nil
        }

        return .peakProductivityTime(hour: peakHour.key)
    }

    /// Analyze nudge compliance rates
    private func analyzeNudgeCompliance() -> [WellnessInsight] {
        var insights: [WellnessInsight] = []
        let todayStats = AdherenceManager.shared.todayStats

        // Blink compliance
        if todayStats.blinkNudgesShown >= 5 {
            let compliance = todayStats.blinkCompliance
            if compliance >= Thresholds.excellentCompliance {
                insights.append(.excellentBlinkCompliance)
            }
        }

        // Posture compliance
        if todayStats.postureNudgesShown >= 3 {
            let compliance = todayStats.postureCompliance
            if compliance < Thresholds.poorCompliance {
                insights.append(.postureNeedsAttention)
            }
        }

        return insights
    }

    /// Analyze session balance
    private func analyzeSessionBalance() -> WellnessInsight? {
        let todayStats = AdherenceManager.shared.todayStats

        if todayStats.longestSessionMinutes >= Thresholds.longSessionMinutes {
            return .longestStretchWarning(minutes: todayStats.longestSessionMinutes)
        }

        return nil
    }

    /// Analyze meeting load
    private func analyzeMeetingLoad() -> WellnessInsight? {
        let todayStats = AdherenceManager.shared.todayStats

        if todayStats.totalMeetingMinutes >= Thresholds.heavyMeetingMinutes {
            return .meetingHeavyDay(minutes: todayStats.totalMeetingMinutes)
        }

        return nil
    }

    /// Analyze schedule consistency
    private func analyzeScheduleConsistency() -> WellnessInsight? {
        let weekStats = AdherenceManager.shared.getDailyStats(days: 7)
        guard weekStats.count >= 5 else { return nil }

        // Check if break counts are consistent across days
        let breakCounts = weekStats.map { $0.breaksCompleted }
        let average = Double(breakCounts.reduce(0, +)) / Double(breakCounts.count)
        let variance =
            breakCounts.map { pow(Double($0) - average, 2) }.reduce(0, +)
            / Double(breakCounts.count)
        let stdDev = sqrt(variance)

        // If standard deviation is low (consistent breaks), show positive insight
        if stdDev <= 2.0 && average >= 3.0 {
            return .consistentSchedule
        }

        return nil
    }

    /// Analyze recovery improvement
    private func analyzeRecovery() -> WellnessInsight? {
        let currentWeek = AdherenceManager.shared.getAggregatedStats(for: .week)
        let previousWeek = AdherenceManager.shared.getPreviousWeekStats()

        guard previousWeek.daysTracked > 0 && currentWeek.daysTracked > 0 else { return nil }

        let currentRecoveryRatio =
            Double(currentWeek.totalBreakMinutes)
            / Double(max(1, currentWeek.breaksCompleted + currentWeek.breaksSkipped))
        let previousRecoveryRatio =
            Double(previousWeek.totalBreakMinutes)
            / Double(max(1, previousWeek.breaksCompleted + previousWeek.breaksSkipped))

        // If taking longer breaks on average this week
        if currentRecoveryRatio > previousRecoveryRatio * 1.2 {
            return .improvedRecovery
        }

        return nil
    }

    /// Recommend optimal break interval based on behavior
    private func recommendBreakInterval() -> WellnessInsight? {
        let todayStats = AdherenceManager.shared.todayStats

        // If user has long sessions but few skips, they might benefit from longer intervals
        // If user skips a lot, suggest shorter intervals
        let totalAttempts = todayStats.breaksCompleted + todayStats.breaksSkipped
        guard totalAttempts >= 4 else { return nil }

        let skipRate = Double(todayStats.breaksSkipped) / Double(totalAttempts)

        if skipRate >= 0.4 {
            // High skip rate - recommend shorter intervals
            return .recommendedBreakInterval(minutes: 20)
        } else if skipRate <= 0.1 && todayStats.longestSessionMinutes < 30 {
            // Very low skip rate and short sessions - could try longer intervals
            return .recommendedBreakInterval(minutes: 30)
        }

        return nil
    }

    // MARK: - Detailed Analysis

    /// Get detailed pattern analysis
    public func getDetailedPatterns() -> [String] {
        var patterns: [String] = []
        let adherence = AdherenceManager.shared

        // Day of week analysis
        let weekStats = adherence.getDailyStats(days: 7)
        if weekStats.count >= 7 {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"

            var dayScores: [String: Double] = [:]
            for day in weekStats {
                let dayName = dayFormatter.string(from: day.date)
                dayScores[dayName] = day.dailyScore
            }

            if let bestDay = dayScores.max(by: { $0.value < $1.value }),
                let worstDay = dayScores.min(by: { $0.value < $1.value }),
                bestDay.value - worstDay.value >= 20
            {
                patterns.append("Your best day is \(bestDay.key) (score: \(Int(bestDay.value))%)")
                patterns.append("Consider extra focus on \(worstDay.key)s")
            }
        }

        // Hour of day analysis
        let distribution = adherence.getHourlyDistribution(for: .week)
        let morningBreaks = (6..<12).reduce(0) { $0 + (distribution[$1] ?? 0) }
        let afternoonBreaks = (12..<18).reduce(0) { $0 + (distribution[$1] ?? 0) }
        let eveningBreaks = (18..<22).reduce(0) { $0 + (distribution[$1] ?? 0) }

        if morningBreaks > afternoonBreaks && morningBreaks > eveningBreaks {
            patterns.append("You take the most breaks in the morning - great way to start!")
        } else if eveningBreaks > morningBreaks {
            patterns.append("You're most active in the evening - consider earlier breaks too")
        }

        return patterns
    }

    /// Get specific recommendations based on current data
    public func getRecommendations() -> [String] {
        var recommendations: [String] = []
        let todayStats = AdherenceManager.shared.todayStats

        // Session length recommendations
        if todayStats.longestSessionMinutes > 45 {
            recommendations.append("Try the Pomodoro technique: 25 min work + 5 min break")
        }

        // Nudge recommendations
        if todayStats.blinkNudgesShown > 0 && todayStats.blinkCompliance < 0.5 {
            recommendations.append("Respond to blink reminders - they help prevent dry eyes")
        }

        if todayStats.postureNudgesShown > 0 && todayStats.postureCompliance < 0.5 {
            recommendations.append(
                "Take a moment when you see posture checks - your back will thank you")
        }

        // Meeting day recommendations
        if todayStats.totalMeetingMinutes > 60 {
            recommendations.append("Heavy meeting day - take extra breaks between calls")
        }

        // Goal recommendations
        if !AdherenceManager.shared.goalMet {
            let remaining = AdherenceManager.shared.dailyBreakGoal - todayStats.breaksCompleted
            if remaining > 0 {
                recommendations.append("Take \(remaining) more break(s) to reach your daily goal")
            }
        }

        return recommendations
    }

    /// Predict if user will meet their daily goal
    public func predictGoalCompletion() -> (likely: Bool, reason: String) {
        let adherence = AdherenceManager.shared
        let todayStats = adherence.todayStats
        let goal = adherence.dailyBreakGoal

        let completed = todayStats.breaksCompleted
        let remaining = goal - completed

        if remaining <= 0 {
            return (true, "Goal already achieved! 🎉")
        }

        // Check time of day
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 22 {
            return (remaining <= 1, remaining <= 1 ? "Almost there!" : "Time is running short")
        } else if hour >= 18 {
            let hoursLeft = 22 - hour
            return (remaining <= hoursLeft, "Evening push needed")
        } else if hour >= 12 {
            return (true, "On track for afternoon progress")
        } else {
            return (true, "Full day ahead")
        }
    }
}
