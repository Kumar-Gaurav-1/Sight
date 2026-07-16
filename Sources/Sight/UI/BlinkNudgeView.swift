import SwiftUI

// MARK: - Blink Nudge View (macOS System Settings Style)

struct BlinkNudgeView: View {
    var onDismiss: (() -> Void)?
    var onSnooze: (() -> Void)?
    var autoDismissSeconds: Double = 4.0

    @State private var blinkAnimation = false
    @State private var snoozeHovered = false

    @StateObject private var state: NudgeState

    private let accentColor = Color.cyan

    init(
        onDismiss: (() -> Void)? = nil,
        onSnooze: (() -> Void)? = nil,
        autoDismissSeconds: Double = 4.0
    ) {
        self.onDismiss = onDismiss
        self.onSnooze = onSnooze
        self.autoDismissSeconds = autoDismissSeconds
        _state = StateObject(wrappedValue: NudgeState(autoDismissSeconds: autoDismissSeconds))
    }

    var body: some View {
        HStack(spacing: 14) {
            // Animated icon with progress ring
            ZStack {
                // Outer glow
                Circle()
                    .fill(accentColor.opacity(blinkAnimation ? 0.12 : 0.05))
                    .frame(width: 52, height: 52)
                    .scaleEffect(blinkAnimation ? 1.1 : 1.0)

                // Background ring
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 44, height: 44)

                // Progress ring (depletes as countdown decreases)
                Circle()
                    .trim(from: 0, to: CGFloat(state.countdown) / CGFloat(autoDismissSeconds))
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: state.countdown)

                // Blinking eye icon
                Image(systemName: blinkAnimation ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .frame(width: 56, height: 56)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: blinkAnimation)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text("Blink Reminder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Close your eyes briefly to refresh")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Blink reminder: Close your eyes briefly to refresh")

            Spacer(minLength: 10)

            // Snooze button with hover
            if onSnooze != nil {
                Button(action: { state.animateDismiss(action: onSnooze) }) {
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
                .accessibilityLabel("Snooze reminder for 5 minutes")
            }

            // Countdown with animation
            Text("\(state.countdown)")
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundColor(.secondary.opacity(0.5))
                .monospacedDigit()
                .frame(width: 26)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: state.countdown)
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
        .nudgeDismiss(state: state, onDismiss: onDismiss)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                blinkAnimation = true
            }
            state.startTimer(onDismiss: onDismiss)
        }
        .onDisappear {
            state.stopTimer()
        }
    }
}

#Preview {
    VStack {
        BlinkNudgeView(onSnooze: {})
            .padding(.horizontal, 20)
        Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
