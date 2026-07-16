import SwiftUI

// MARK: - Overtime Nudge View (LookAway Style - Enhanced)

struct OvertimeNudgeView: View {
    let elapsedMinutes: Int
    var onDismiss: (() -> Void)?
    var autoDismissSeconds: Double = 8.0

    @State private var pulse = false
    @State private var countdown: Int
    @State private var timer: Timer?
    @State private var takeBreakHovered = false
    @StateObject private var nudgeState = NudgeState()

    private let accentColor = Color.red

    init(elapsedMinutes: Int, onDismiss: (() -> Void)? = nil, autoDismissSeconds: Double = 8.0) {
        self.elapsedMinutes = elapsedMinutes
        self.onDismiss = onDismiss
        self.autoDismissSeconds = autoDismissSeconds
        _countdown = State(initialValue: Int(autoDismissSeconds))
    }

    var body: some View {
        HStack(spacing: 14) {
            // Pulsing warning icon with progress ring
            ZStack {
                // Outer pulse glow
                Circle()
                    .fill(accentColor.opacity(pulse ? 0.15 : 0.05))
                    .frame(width: 52, height: 52)
                    .scaleEffect(pulse ? 1.15 : 1.0)

                // Background ring
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 44, height: 44)

                // Progress ring (depletes as countdown decreases)
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / CGFloat(autoDismissSeconds))
                    .stroke(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)

                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .frame(width: 56, height: 56)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text("Overtime Alert")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(elapsedMinutes) minutes without a break")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            // Take Break button with hover
            Button(action: { nudgeState.dismiss(stopTimer: stopTimer, immediateAction: { NotificationCenter.default.post(name: NSNotification.Name("SightTakeBreak"), object: nil) }, delayedAction: { onDismiss?() }) }) {
                Text("Take Break")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(takeBreakHovered ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: takeBreakHovered)
            .onHover { takeBreakHovered = $0 }

            // Countdown with animation
            Text("\(countdown)")
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundColor(.secondary.opacity(0.5))
                .monospacedDigit()
                .frame(width: 26)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: countdown)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .frame(width: 400, height: 80)
        .background(
            Capsule()
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
        )
        .overlay(
            Capsule()
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
        .nudgeGestures(state: nudgeState, stopTimer: stopTimer, onDismiss: onDismiss)
        .onAppear { startTimers() }
        .onDisappear { stopTimer() }
    }

    private func startTimers() {
        // Start pulse animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulse = true
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] t in
            guard !nudgeState.isDismissing else {
                t.invalidate()
                return
            }

            if countdown > 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    countdown -= 1
                }
            } else {
                t.invalidate()
                nudgeState.dismiss(stopTimer: stopTimer) { onDismiss?() }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    VStack {
        OvertimeNudgeView(elapsedMinutes: 45)
            .padding(.horizontal, 20)
        Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
