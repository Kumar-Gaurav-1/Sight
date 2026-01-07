import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Enhanced Statistics View

/// Premium statistics screen with comprehensive break activity, wellness metrics, and insights
struct SightStatisticsView: View {
    @ObservedObject private var adherence = AdherenceManager.shared
    @State private var selectedPeriod: AdherenceManager.StatsPeriod = .today
    @State private var showResetConfirmation = false
    @State private var animateStats = false
    @State private var insights: [WellnessInsight] = []
    @State private var isLoading = true

    private var periodStats: AdherenceManager.AggregatedStats {
        adherence.getAggregatedStats(for: selectedPeriod)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (Native Style already handled by window title usually, but keeping simple title)
            // header
            Text("Statistics")
                .font(.largeTitle.bold())
                .padding(.horizontal, 20)
                .padding(.top, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Wellness Score & Hero Stats
                    wellnessSection

                    // Time Breakdown
                    timeBreakdownSection

                    // Weekly Chart
                    weeklyChartCard

                    // Insights Section
                    if !insights.isEmpty {
                        insightsSection
                    }

                    // Comparison Section
                    comparisonSection

                    // Nudge Analytics
                    nudgeAnalyticsSection

                    // Period Stats
                    periodStatsSection

                    // Actions
                    actionsSection
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            // Force refresh stats from storage first
            adherence.forceRefresh()

            // Brief loading for better UX
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms
                await MainActor.run {
                    insights = InsightsEngine.shared.generateInsights()
                    isLoading = false
                    withAnimation(SightTheme.springSmooth.delay(0.1)) {
                        animateStats = true
                    }
                }
            }
        }
        .onChange(of: selectedPeriod) { _ in
            // Refresh insights when period changes
            isLoading = true
            Task {
                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
                await MainActor.run {
                    insights = InsightsEngine.shared.generateInsights()
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Header

    // MARK: - Header
    // (Header view removed in favor of simple text above)
    // private var header: some View { ... }

    // MARK: - Wellness Section

    private var wellnessSection: some View {
        HStack(spacing: 16) {
            // Wellness Gauge
            WellnessGaugeView(
                score: adherence.todayStats.wellnessScore,
                animate: animateStats
            )

            // Hero Stats
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MiniStatCard(
                        icon: "checkmark.circle.fill",
                        value: "\(adherence.todayStats.breaksCompleted)",
                        label: "Breaks",
                        color: SightTheme.success,
                        animate: animateStats
                    )

                    MiniStatCard(
                        icon: "clock.fill",
                        value: "\(adherence.todayStats.totalBreakMinutes)m",
                        label: "Rested",
                        color: SightTheme.accent,
                        animate: animateStats
                    )
                }

                HStack(spacing: 12) {
                    MiniStatCard(
                        icon: "flame.fill",
                        value: "\(adherence.currentStreak)",
                        label: "Streak",
                        color: .orange,
                        animate: animateStats
                    )

                    MiniStatCard(
                        icon: "target",
                        value: String(format: "%.0f%%", adherence.goalProgress * 100),
                        label: "Goal",
                        color: adherence.goalMet ? SightTheme.success : SightTheme.accent,
                        animate: animateStats
                    )
                }
            }
        }
        .padding(16)
        .background(SightTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Time Breakdown Section

    private var timeBreakdownSection: some View {
        EnhancedSettingsCard(
            icon: "clock.badge.checkmark.fill",
            iconColor: SightTheme.accent,
            title: "Today's Time",
            delay: 0
        ) {
            TimeBreakdownChart(
                screenTime: adherence.todayStats.totalScreenTimeMinutes,
                breakTime: adherence.todayStats.totalBreakMinutes,
                meetingTime: adherence.todayStats.totalMeetingMinutes,
                idleTime: adherence.todayStats.totalIdleMinutes,
                animate: animateStats
            )
            .padding(16)
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(SightTheme.accent)
                Text("Insights")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 8) {
                ForEach(insights.prefix(4)) { insight in
                    InsightCardView(insight: insight)
                }
            }
        }
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        EnhancedSettingsCard(
            icon: "arrow.left.arrow.right",
            iconColor: .purple,
            title: "This Week vs Last Week",
            delay: 0.05
        ) {
            VStack(spacing: 16) {
                let current = adherence.getAggregatedStats(for: .week)
                let previous = adherence.getPreviousWeekStats()

                ComparisonBarView(
                    currentValue: Double(current.breaksCompleted),
                    previousValue: Double(previous.breaksCompleted),
                    label: "Breaks Completed",
                    format: "%.0f",
                    animate: animateStats
                )

                ComparisonBarView(
                    currentValue: current.averageScore,
                    previousValue: previous.averageScore,
                    label: "Average Score",
                    format: "%.0f%%",
                    animate: animateStats
                )

                ComparisonBarView(
                    currentValue: Double(current.totalBreakMinutes),
                    previousValue: Double(previous.totalBreakMinutes),
                    label: "Total Rest Time",
                    format: "%.0f min",
                    animate: animateStats
                )
            }
            .padding(16)
        }
    }

    // MARK: - Nudge Analytics Section

    private var nudgeAnalyticsSection: some View {
        EnhancedSettingsCard(
            icon: "hand.raised.fill",
            iconColor: SightTheme.success,
            title: "Nudge Compliance",
            delay: 0.06
        ) {
            NudgeComplianceCard(
                blinkShown: adherence.todayStats.blinkNudgesShown,
                blinkFollowed: adherence.todayStats.blinkNudgesFollowed,
                postureShown: adherence.todayStats.postureNudgesShown,
                postureFollowed: adherence.todayStats.postureNudgesFollowed,
                animate: animateStats
            )
            .padding(16)
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartCard: some View {
        EnhancedSettingsCard(
            icon: "chart.bar.fill",
            iconColor: SightTheme.accent,
            title: "Last 7 Days",
            delay: 0
        ) {
            VStack(spacing: 16) {
                AnimatedBarChart(
                    dailyStats: adherence.getDailyStats(days: 7), animate: animateStats)

                // Legend
                HStack(spacing: 20) {
                    LegendItem(color: SightTheme.success, label: "80%+ score")
                    LegendItem(color: SightTheme.warning, label: "50-79%")
                    LegendItem(color: SightTheme.accent, label: "<50%")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
    }

    // MARK: - Period Stats

    private var periodStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detailed Stats")
                    .font(.system(size: 16, weight: .bold))
                Text("Detailed Stats")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // Period selector
                HStack(spacing: 0) {
                    ForEach(AdherenceManager.StatsPeriod.allCases, id: \.self) { period in
                        PeriodButton(
                            title: period.rawValue,
                            isSelected: selectedPeriod == period
                        ) {
                            withAnimation(SightTheme.springSnappy) {
                                selectedPeriod = period
                            }
                        }
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailStatCard(
                    icon: "checkmark.seal.fill",
                    title: "Completed",
                    value: "\(periodStats.breaksCompleted)",
                    subtitle: "breaks taken",
                    color: SightTheme.success
                )

                DetailStatCard(
                    icon: "forward.end.fill",
                    title: "Skipped",
                    value: "\(periodStats.breaksSkipped)",
                    subtitle: "breaks missed",
                    color: SightTheme.warning
                )

                DetailStatCard(
                    icon: "bolt.fill",
                    title: "Short Breaks",
                    value: "\(periodStats.shortBreaksCompleted)",
                    subtitle: "20-second rests",
                    color: SightTheme.accent
                )

                DetailStatCard(
                    icon: "moon.fill",
                    title: "Long Breaks",
                    value: "\(periodStats.longBreaksCompleted)",
                    subtitle: "extended rests",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Export
            EnhancedSettingsCard(
                icon: "square.and.arrow.up",
                iconColor: SightTheme.accent,
                title: "Export Data",
                delay: 0.05
            ) {
                HStack {
                    Text("Download your break history")
                        .font(.system(size: 13))
                        .foregroundColor(SightTheme.secondaryText)

                    Spacer()

                    HStack(spacing: 8) {
                        ExportButton(label: "JSON", action: exportJSON)
                        ExportButton(label: "CSV", action: exportCSV)
                    }
                }
                .padding(16)
            }

            // Reset
            EnhancedSettingsCard(
                icon: "arrow.counterclockwise",
                iconColor: SightTheme.danger,
                title: "Reset Statistics",
                delay: 0.1
            ) {
                HStack {
                    Text("Clear all history and start fresh")
                        .font(.system(size: 13))
                        .foregroundColor(SightTheme.secondaryText)

                    Spacer()

                    Button(action: { showResetConfirmation = true }) {
                        Text("Reset All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(SightTheme.danger))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .alert("Reset All Statistics?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    adherence.resetAllStats()
                }
            } message: {
                Text("This will permanently delete all your break history.")
            }
        }
    }

    // MARK: - Export

    private func exportJSON() {
        Task.detached(priority: .userInitiated) {
            guard let data = await MainActor.run(body: { self.adherence.exportAsJSON() }) else {
                return
            }

            await MainActor.run {
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.json]
                savePanel.nameFieldStringValue = "sight-statistics.json"

                if savePanel.runModal() == .OK, let url = savePanel.url {
                    try? data.write(to: url)
                }
            }
        }
    }

    private func exportCSV() {
        Task.detached(priority: .userInitiated) {
            let csv = await MainActor.run(body: { self.adherence.exportAsCSV() })

            await MainActor.run {
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.commaSeparatedText]
                savePanel.nameFieldStringValue = "sight-statistics.csv"

                if savePanel.runModal() == .OK, let url = savePanel.url {
                    try? csv.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let animate: Bool

    @State private var isHovered = false
    @State private var isAnimated = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimated ? 1 : 0.8)
                    .opacity(isAnimated ? 1 : 0)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(SightTheme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .onHover { isHovered = $0 }
        .onAppear {
            if animate {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    isAnimated = true
                }
            }
        }
    }
}

// MARK: - Hero Stat Card (Legacy)

struct HeroStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let animate: Bool

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SightTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SightTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(SightTheme.secondaryText)

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(SightTheme.tertiaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SightTheme.cardBackground)
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Animated Bar Chart

struct AnimatedBarChart: View {
    let dailyStats: [AdherenceManager.DayStats]
    let animate: Bool

    private let barMaxHeight: CGFloat = 100
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private var maxBreaks: Int {
        max(1, dailyStats.map { $0.breaksCompleted }.max() ?? 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            let paddedStats = padStatsToSevenDays()

            ForEach(Array(paddedStats.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 8) {
                    // Value label
                    Text("\(day.breaksCompleted)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(day.breaksCompleted > 0 ? .white : SightTheme.tertiaryText)
                        .opacity(animate ? 1 : 0)

                    // Bar
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barGradient(for: day))
                        .frame(height: animate ? barHeight(for: day.breaksCompleted) : 8)

                    // Day
                    Text(dayFormatter.string(from: day.date))
                        .font(
                            .system(
                                size: 11,
                                weight: Calendar.current.isDateInToday(day.date) ? .bold : .medium)
                        )
                        .foregroundColor(
                            Calendar.current.isDateInToday(day.date)
                                ? .white : SightTheme.secondaryText
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: barMaxHeight + 50)
    }

    private func padStatsToSevenDays() -> [AdherenceManager.DayStats] {
        let calendar = Calendar.current
        var result: [AdherenceManager.DayStats] = []

        for daysAgo in (0..<7).reversed() {
            let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let targetDayStart = calendar.startOfDay(for: targetDate)

            if let existing = dailyStats.first(where: {
                calendar.isDate($0.date, inSameDayAs: targetDayStart)
            }) {
                result.append(existing)
            } else {
                result.append(AdherenceManager.DayStats(date: targetDayStart))
            }
        }

        return result
    }

    private func barHeight(for breaks: Int) -> CGFloat {
        guard maxBreaks > 0 else { return 12 }
        return max(12, CGFloat(breaks) / CGFloat(maxBreaks) * barMaxHeight)
    }

    private func barGradient(for day: AdherenceManager.DayStats) -> LinearGradient {
        let color: Color
        if day.breaksCompleted == 0 {
            color = SightTheme.cardBackground
        } else if day.dailyScore >= 80 {
            color = SightTheme.success
        } else if day.dailyScore >= 50 {
            color = SightTheme.warning
        } else {
            color = SightTheme.accent
        }

        return LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Supporting Views

struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : SightTheme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? SightTheme.accent : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(SightTheme.tertiaryText)
        }
    }
}

struct ExportButton: View {
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isHovered ? SightTheme.accent : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    SightStatisticsView()
        .frame(width: 700, height: 800)
}
