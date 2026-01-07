import SwiftUI

// MARK: - Mini Exercise Nudge View (LookAway Style - Enhanced)

struct MiniExerciseNudgeView: View {
    var onDismiss: (() -> Void)?
    var onSnooze: (() -> Void)?
    var autoDismissSeconds: Double = 6.0

    @State private var bounce = false
    @State private var countdown: Int
    @State private var dragY: CGFloat = 0
    @State private var timer: Timer?
    @State private var snoozeHovered = false
    @State private var isDismissing = false  // Prevent double dismiss

    private let accentColor = Color.green

    // Random exercise suggestions
    private let exercises = [
        ("Stretch your arms overhead", "figure.arms.open"),
        ("Roll your shoulders", "figure.walk"),
        ("Stand up and stretch", "figure.stand"),
        ("Touch your toes", "figure.flexibility"),
        ("Rotate your wrists", "hand.raised.fingers.spread"),
    ]

    @State private var selectedExercise: (String, String)

    init(
        onDismiss: (() -> Void)? = nil,
        onSnooze: (() -> Void)? = nil,
        autoDismissSeconds: Double = 6.0
    ) {
        self.onDismiss = onDismiss
        self.onSnooze = onSnooze
        self.autoDismissSeconds = autoDismissSeconds
        _countdown = State(initialValue: Int(autoDismissSeconds))
        _selectedExercise = State(initialValue: exercises.randomElement()!)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Animated icon with progress ring
            ZStack {
                // Outer glow
                Circle()
                    .fill(accentColor.opacity(bounce ? 0.12 : 0.05))
                    .frame(width: 52, height: 52)
                    .scaleEffect(bounce ? 1.1 : 1.0)

                // Background ring
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 44, height: 44)

                // Progress ring (depletes as countdown decreases)
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / CGFloat(autoDismissSeconds))
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)

                // Bouncing exercise icon
                Image(systemName: selectedExercise.1)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
                    .offset(y: bounce ? -2 : 2)
            }
            .frame(width: 56, height: 56)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: bounce)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text("Quick Stretch")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(selectedExercise.0)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            // Snooze button with hover
            if onSnooze != nil {
                Button(action: { snooze() }) {
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
        .offset(y: dragY)
        .gesture(
            DragGesture()
                .onChanged { dragY = min(0, $0.translation.height * 0.6) }
                .onEnded { value in
                    if value.translation.height < -30 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3)) { dragY = 0 }
                    }
                }
        )
        .onTapGesture { dismiss() }
        .onAppear { startTimers() }
        .onDisappear { stopTimer() }
    }

    private func startTimers() {
        // Start bounce animation
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            bounce = true
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] t in
            guard !isDismissing else {
                t.invalidate()
                return
            }

            if countdown > 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    countdown -= 1
                }
            } else {
                t.invalidate()
                dismiss()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true

        stopTimer()
        withAnimation(.spring(response: 0.3)) {
            dragY = -60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss?()
        }
    }

    private func snooze() {
        guard !isDismissing else { return }
        isDismissing = true

        stopTimer()
        withAnimation(.spring(response: 0.3)) {
            dragY = -60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSnooze?()
        }
    }
}

#Preview {
    VStack {
        MiniExerciseNudgeView(onSnooze: {})
            .padding(.horizontal, 20)
        Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
