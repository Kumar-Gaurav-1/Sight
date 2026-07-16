import SwiftUI

// MARK: - Posture Nudge View (LookAway Style - Enhanced)

struct PostureNudgeView: View {
    var onDismiss: (() -> Void)?
    var onSnooze: (() -> Void)?
    var autoDismissSeconds: Double = 4.0

    @State private var arrowBounce = false
    @State private var countdown: Int
    @State private var timer: Timer?
    @State private var snoozeHovered = false
    @State private var isHovered = false
    @StateObject private var nudgeState = NudgeState()

    private let accentColor = Color.orange

    init(
        onDismiss: (() -> Void)? = nil,
        onSnooze: (() -> Void)? = nil,
        autoDismissSeconds: Double = 4.0
    ) {
        self.onDismiss = onDismiss
        self.onSnooze = onSnooze
        self.autoDismissSeconds = autoDismissSeconds
        _countdown = State(initialValue: Int(autoDismissSeconds))
    }

    var body: some View {
        HStack(spacing: 14) {
            // Animated icon with progress ring
            ZStack {
                // Outer glow
                Circle()
                    .fill(accentColor.opacity(arrowBounce ? 0.12 : 0.05))
                    .frame(width: 52, height: 52)
                    .scaleEffect(arrowBounce ? 1.1 : 1.0)

                // Background ring
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 44, height: 44)

                // Progress ring (depletes as countdown decreases)
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / CGFloat(autoDismissSeconds))
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)

                // Icon with bounce animation
                ZStack {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 15, weight: .semibold))

                    Image(systemName: "chevron.up")
                        .font(.system(size: 7, weight: .bold))
                        .offset(x: 9, y: arrowBounce ? -6 : -2)
                }
                .foregroundColor(accentColor)
            }
            .frame(width: 56, height: 56)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: arrowBounce)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text("Posture Check")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Sit up straight, shoulders back")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            // Snooze button with hover
            if onSnooze != nil {
                Button(action: { nudgeState.dismiss(stopTimer: stopTimer) { onSnooze?() } }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(snoozeHovered ? .primary : .secondary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(snoozeHovered ? 0.1 : 0.05))
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(snoozeHovered ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.15), value: snoozeHovered)
                .onHover { snoozeHovered = $0 }
                .help("Snooze for 5 minutes")
            }

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
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .nudgeGestures(state: nudgeState, stopTimer: stopTimer, onDismiss: onDismiss)
        .onAppear { startTimers() }
        .onDisappear { stopTimer() }
    }

    private func startTimers() {
        // Start arrow bounce animation
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            arrowBounce = true
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
        PostureNudgeView(onSnooze: {})
            .padding(.horizontal, 20)
        Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
