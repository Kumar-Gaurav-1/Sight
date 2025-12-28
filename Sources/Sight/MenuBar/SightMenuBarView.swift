import SwiftUI

// MARK: - Menu Bar Dashboard

struct SightMenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @ObservedObject var adherence = AdherenceManager.shared

    var body: some View {
        VStack(spacing: 0) {
            timerSection
                .padding(16)

            Divider()
                .background(Color.white.opacity(0.1))

            statsRow
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

            Divider()
                .background(Color.white.opacity(0.1))

            actionButtons
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
        }
        .frame(width: 280)
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Timer Section

    private var isIdle: Bool {
        viewModel.currentState == .idle
    }

    private var isTimerPaused: Bool {
        viewModel.isPaused
    }

    private var isOnBreak: Bool {
        viewModel.currentState == .break
    }

    private var pauseReasonText: String {
        if let reason = WorkHoursManager.shared.pauseReason {
            return reason
        } else if SmartPauseManager.shared.shouldPause {
            return SmartPauseManager.shared.activeSignals.first?.description ?? "Smart Pause"
        } else if IdleDetector.shared.isIdle {
            return "User Away"
        } else if isTimerPaused {
            return "Paused"
        }
        return "Ready to start"
    }

    private var statusColor: Color {
        if isOnBreak { return .cyan }
        if isIdle || isTimerPaused { return .orange }
        return .green
    }

    private var statusText: String {
        if isOnBreak { return "On Break" }
        if isTimerPaused { return "Paused" }
        if isIdle { return "Stopped" }
        return "Active"
    }

    private var timerSection: some View {
        HStack(spacing: 14) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        isIdle ? Color.orange : Color.cyan,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Image(systemName: isIdle ? "pause.fill" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isIdle ? .orange : .cyan)
            }

            // Time info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(statusText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text(formatTime(viewModel.remainingSeconds))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()

                if isOnBreak {
                    Text("Break ends in \(viewModel.remainingSeconds)s")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                } else if let eta = viewModel.nextBreakText {
                    Text(eta)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else if isIdle || isTimerPaused {
                    Text(pauseReasonText)
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Play/Pause
            Button(action: { viewModel.toggleTimer() }) {
                Image(systemName: isIdle ? "play.fill" : "pause.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(adherence.todayStats.breaksCompleted)", label: "Breaks")

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 24)

            StatItem(value: "\(adherence.currentStreak)d", label: "Streak")

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 24)

            StatItem(
                value: "\(Int(min(adherence.goalProgress, 1) * 100))%",
                label: "Goal"
            )
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func openSettings() {
        // Close the menu first, then open preferences
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
        }
    }

    // MARK: - Action Buttons

    private func closeMenu() {
        // Close the menu by simulating escape key
        DispatchQueue.main.async {
            NSApp.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if isOnBreak {
                // During break - allow skip
                ActionButton(icon: "forward.fill", title: "Skip") {
                    closeMenu()
                    viewModel.skipBreak()
                }
            } else if isIdle {
                // Stopped - show start
                ActionButton(icon: "play.fill", title: "Start") {
                    closeMenu()
                    viewModel.toggleTimer()
                }
            } else {
                // Working - show break and postpone
                ActionButton(icon: "cup.and.saucer.fill", title: "Break") {
                    closeMenu()
                    viewModel.triggerShortBreak()
                }

                ActionButton(icon: "clock.arrow.circlepath", title: "+5 min") {
                    closeMenu()
                    viewModel.postponeBreak()
                }
            }

            ActionButton(icon: "gearshape.fill", title: "Settings") {
                openSettings()
            }

            ActionButton(icon: "power", title: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? .cyan : .primary)

                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovered ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
