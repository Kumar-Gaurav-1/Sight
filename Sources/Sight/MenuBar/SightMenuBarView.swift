import SwiftUI

// MARK: - Menu Bar View (macOS System Settings Style - Enhanced)

struct SightMenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @ObservedObject var adherence = AdherenceManager.shared

    @State private var hoveredRow: String?
    @State private var playButtonHovered = false
    @State private var ringPulse = false

    // MARK: - Theme

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.7, blue: 0.5), Color(red: 0.3, green: 0.75, blue: 0.85),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Section with Timer Ring
            headerSection

            // Subtle separator
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            // Status Section
            statusSection

            // Subtle separator
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            // Quick Actions
            actionsSection
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            if viewModel.currentState == .work && !viewModel.isPaused {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    ringPulse = true
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Timer Ring with pulse
            ZStack {
                // Pulse glow when active
                if viewModel.currentState == .work && !viewModel.isPaused {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(ringPulse ? 0.2 : 0.05), Color.clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)
                }

                // Background ring
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 3.5)
                    .frame(width: 42, height: 42)

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        accentGradient,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.cyan.opacity(0.3), radius: 4)
                    .animation(.linear(duration: 0.5), value: timerProgress)

                // Eye icon
                Image(systemName: "eye.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentGradient)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Sight")
                        .font(.system(size: 13, weight: .semibold))

                    // Status badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 5, height: 5)
                        Text(statusText)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.12))
                    )
                }

                Text(timeDisplay)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Pause/Play button
            Button(action: {
                viewModel.toggleTimer()
            }) {
                Image(systemName: isPausedOrIdle ? "play.fill" : "pause.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(playButtonHovered ? .primary : .secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(playButtonHovered ? 0.12 : 0.06))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(playButtonHovered ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: playButtonHovered)
            .onHover { playButtonHovered = $0 }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 0) {
            // Breaks Today
            StatusRow(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "Breaks Today",
                value: "\(adherence.todayStats.breaksCompleted)",
                isHovered: hoveredRow == "breaks"
            )
            .onHover { hoveredRow = $0 ? "breaks" : nil }

            // Wellness Score
            StatusRow(
                icon: "heart.fill",
                iconColor: .pink,
                title: "Wellness Score",
                value: "\(Int(adherence.todayStats.wellnessScore))%",
                valueColor: wellnessColor,
                isHovered: hoveredRow == "wellness"
            )
            .onHover { hoveredRow = $0 ? "wellness" : nil }

            // Screen Time
            StatusRow(
                icon: "desktopcomputer",
                iconColor: .orange,
                title: "Screen Time",
                value: formatScreenTime(adherence.todayStats.totalScreenTimeMinutes),
                isHovered: hoveredRow == "screen"
            )
            .onHover { hoveredRow = $0 ? "screen" : nil }

            // Current Streak
            StatusRow(
                icon: "flame.fill",
                iconColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                title: "Current Streak",
                value: "\(adherence.currentStreak)d",
                isHovered: hoveredRow == "streak"
            )
            .onHover { hoveredRow = $0 ? "streak" : nil }
        }
        .padding(.vertical, 4)
    }

    private var wellnessColor: Color {
        let score = adherence.todayStats.wellnessScore
        if score >= 80 { return .green } else if score >= 50 { return .orange } else { return .red }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 0) {
            // Take Break
            ActionRow(
                icon: "cup.and.saucer.fill",
                title: "Take Break Now",
                color: .cyan,
                shortcut: "⌘⇧B"
            ) {
                viewModel.triggerShortBreak()
                closeMenu()
            }

            // Settings
            ActionRow(
                icon: "gearshape.fill",
                title: "Preferences...",
                color: Color(white: 0.5),
                shortcut: "⌘,"
            ) {
                openSettings()
            }

            // Quit
            ActionRow(
                icon: "power",
                title: "Quit Sight",
                color: .red,
                shortcut: "⌘Q"
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var timerProgress: CGFloat {
        guard viewModel.currentState == .work else { return 0 }
        let total = PreferencesManager.shared.workIntervalSeconds
        let elapsed = total - viewModel.remainingSeconds
        return CGFloat(elapsed) / CGFloat(total)
    }

    private var isPausedOrIdle: Bool {
        viewModel.currentState == .idle || viewModel.isPaused
    }

    private var statusText: String {
        if viewModel.isPaused { return "Paused" }
        switch viewModel.currentState {
        case .idle: return "Idle"
        case .work: return "Active"
        case .preBreak: return "Starting"
        case .break: return "Break"
        }
    }

    private var statusColor: Color {
        if viewModel.isPaused { return .orange }
        switch viewModel.currentState {
        case .idle: return .gray
        case .work: return .green
        case .preBreak: return .yellow
        case .break: return .cyan
        }
    }

    private var timeDisplay: String {
        if viewModel.currentState == .idle { return "Timer not running" }
        let mins = viewModel.remainingSeconds / 60
        let secs = viewModel.remainingSeconds % 60
        return String(format: "Next break in %d:%02d", mins, secs)
    }

    private func formatScreenTime(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    private func closeMenu() {
        NSApp.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
    }

    private func openSettings() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
        }
    }
}

// MARK: - Status Row (Enhanced)

private struct StatusRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var valueColor: Color = .primary
    var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            // Icon with gradient background
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(iconColor.gradient)
                        .shadow(color: iconColor.opacity(0.3), radius: 2, y: 1)
                )

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .padding(.horizontal, 4)
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Action Row (Enhanced)

private struct ActionRow: View {
    let icon: String
    let title: String
    let color: Color
    var shortcut: String? = nil
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon with gradient
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(color.gradient)
                            .shadow(color: color.opacity(0.3), radius: 2, y: 1)
                    )

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                Spacer()

                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
