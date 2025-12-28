import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Statistics View

/// Premium statistics screen with break activity and metrics
struct SightStatisticsView: View {
    @ObservedObject private var adherence = AdherenceManager.shared
    @State private var selectedPeriod: AdherenceManager.StatsPeriod = .today
    @State private var showResetConfirmation = false
    @State private var animateStats = false

    private var periodStats: AdherenceManager.AggregatedStats {
        adherence.getAggregatedStats(for: selectedPeriod)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Stats
                    heroStatsRow

                    // Weekly Chart
                    weeklyChartCard

                    // Period Stats
                    periodStatsSection

                    // Actions
                    actionsSection
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(SightTheme.background)
        .onAppear {
            withAnimation(SightTheme.springSmooth.delay(0.2)) {
                animateStats = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Statistics")
                    .font(SightTheme.titleFont)
                    .foregroundColor(.white)

                Text("Track your break habits")
                    .font(.system(size: 13))
                    .foregroundColor(SightTheme.secondaryText)
            }

            Spacer()

            Button(action: {
                // Close preferences window first so break overlay is visible
                NSApp.keyWindow?.close()
                // Post notification for AppDelegate to handle - ensures proper timer pause
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightTakeBreak"), object: nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 12))
                    Text("Take Break")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(SightTheme.accent)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, SightTheme.sectionSpacing)
        .padding(.top, SightTheme.sectionSpacing)
        .padding(.bottom, 16)
    }

    // MARK: - Hero Stats Row

    private var heroStatsRow: some View {
        HStack(spacing: 12) {
            HeroStatCard(
                icon: "checkmark.circle.fill",
                value: "\(adherence.todayStats.breaksCompleted)",
                label: "Breaks",
                color: SightTheme.success,
                animate: animateStats
            )

            HeroStatCard(
                icon: "clock.fill",
                value: "\(adherence.todayStats.totalBreakMinutes)m",
                label: "Rested",
                color: SightTheme.accent,
                animate: animateStats
            )

            HeroStatCard(
                icon: "flame.fill",
                value: "\(adherence.currentStreak)",
                label: "Streak",
                color: .orange,
                animate: animateStats
            )

            HeroStatCard(
                icon: "chart.line.uptrend.xyaxis",
                value: String(format: "%.0f%%", adherence.todayStats.dailyScore),
                label: "Score",
                color: scoreColor(adherence.todayStats.dailyScore),
                animate: animateStats
            )
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return SightTheme.success }
        if score >= 50 { return SightTheme.warning }
        return SightTheme.danger
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
                    .foregroundColor(.white)

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
                    value:
                        "\(periodStats.breaksCompleted > 0 ? max(0, periodStats.breaksCompleted - periodStats.shortBreaksCompleted - periodStats.longBreaksCompleted) : 0)",
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
        guard let data = adherence.exportAsJSON() else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "sight-statistics.json"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? data.write(to: url)
        }
    }

    private func exportCSV() {
        let csv = adherence.exportAsCSV()

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "sight-statistics.csv"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Hero Stat Card

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
        .frame(width: 700, height: 700)
}
