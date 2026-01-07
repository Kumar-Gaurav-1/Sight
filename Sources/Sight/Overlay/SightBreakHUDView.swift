import Combine
import SwiftUI

// MARK: - Break Overlay View (macOS System Style - Enhanced)

struct SightBreakHUDView: View {
    let duration: Int
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var timeRemaining: Int
    @State private var progress: CGFloat = 1
    @State private var appear = false
    @State private var breathe = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathTimer: Timer?
    @State private var elapsedSeconds: Int = 0
    @State private var targetDate: Date?
    @State private var skipHovered = false
    @State private var doneHovered = false

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let breathDuration: Double = 4.0

    // MARK: - Theme Colors

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.3, green: 0.7, blue: 0.9), Color(red: 0.2, green: 0.8, blue: 0.6),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentColor: Color {
        Color(red: 0.3, green: 0.75, blue: 0.85)
    }

    enum BreathPhase: String {
        case inhale, exhale
        var text: String {
            switch self {
            case .inhale: return "Breathe in"
            case .exhale: return "Breathe out"
            }
        }
        var icon: String {
            switch self {
            case .inhale: return "chevron.down"
            case .exhale: return "chevron.up"
            }
        }
    }

    // MARK: - Position Helpers

    /// Get horizontal alignment from preference
    private var horizontalAlignment: HorizontalAlignment {
        let position = PreferencesManager.shared.breakAlertPosition
        if position.contains("Left") {
            return .leading
        } else if position.contains("Right") {
            return .trailing
        }
        return .center
    }

    /// Get vertical alignment from preference
    private var verticalAlignment: VerticalAlignment {
        let position = PreferencesManager.shared.breakAlertPosition
        if position.contains("top") {
            return .top
        } else if position.contains("bottom") {
            return .bottom
        }
        return .center
    }

    /// Combined alignment for ZStack
    private var cardAlignment: Alignment {
        let position = PreferencesManager.shared.breakAlertPosition
        switch position {
        case "topLeft": return .topLeading
        case "topCenter": return .top
        case "topRight": return .topTrailing
        case "bottomLeft": return .bottomLeading
        case "bottomCenter": return .bottom
        case "bottomRight": return .bottomTrailing
        default: return .center
        }
    }

    /// Edge padding based on position
    private var cardPadding: EdgeInsets {
        let position = PreferencesManager.shared.breakAlertPosition
        let hPad: CGFloat = 40
        let vPad: CGFloat = 60

        switch position {
        case "topLeft": return EdgeInsets(top: vPad, leading: hPad, bottom: 0, trailing: 0)
        case "topCenter": return EdgeInsets(top: vPad, leading: 0, bottom: 0, trailing: 0)
        case "topRight": return EdgeInsets(top: vPad, leading: 0, bottom: 0, trailing: hPad)
        case "bottomLeft": return EdgeInsets(top: 0, leading: hPad, bottom: vPad, trailing: 0)
        case "bottomCenter": return EdgeInsets(top: 0, leading: 0, bottom: vPad, trailing: 0)
        case "bottomRight": return EdgeInsets(top: 0, leading: 0, bottom: vPad, trailing: hPad)
        default: return EdgeInsets()
        }
    }

    init(duration: Int, onSkip: @escaping () -> Void) {
        self.duration = duration
        self.onSkip = onSkip
        _timeRemaining = State(initialValue: duration)
    }

    var body: some View {
        ZStack(alignment: cardAlignment) {
            // Dimmed background with subtle gradient
            backgroundOverlay

            // Positioned card based on user preference
            mainCard
                .padding(cardPadding)
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
        .onDisappear { stopTimers() }
        .onReceive(timer) { _ in updateTimer() }
    }

    // MARK: - Background

    private var backgroundOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)

            // Subtle radial gradient for depth
            RadialGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.3),
                ],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
        }
    }

    // MARK: - Main Card

    private var mainCard: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Subtle separator
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            // Main content
            VStack(spacing: 28) {
                // Timer ring
                timerRing
                    .padding(.top, 8)

                // Time display
                timeDisplay

                // Breathing guide
                breathingGuide

                // Progress section
                progressSection
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)

            // Subtle separator
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            // Footer
            footerSection
        }
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 60, y: 20)
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            // App icon styled circle
            ZStack {
                Circle()
                    .fill(accentGradient)
                    .frame(width: 28, height: 28)

                Image(systemName: "eye")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Take a Break")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // Keyboard badge - macOS style
            HStack(spacing: 2) {
                Text("esc")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            // Outer shadow ring for depth
            Circle()
                .stroke(Color.primary.opacity(0.04), lineWidth: 12)
                .frame(width: 130, height: 130)

            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                .frame(width: 130, height: 130)

            // Progress ring with glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accentGradient,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .shadow(color: accentColor.opacity(0.4), radius: 8, x: 0, y: 0)
                .animation(.linear(duration: 0.1), value: progress)

            // Inner breathing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(breathe ? 0.25 : 0.1),
                            accentColor.opacity(0.03),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 45
                    )
                )
                .frame(width: 90, height: 90)
                .scaleEffect(breathe ? 1.2 : 0.85)
                .animation(
                    .easeInOut(duration: breathDuration).repeatForever(autoreverses: true),
                    value: breathe
                )

            // Center eye icon
            Image(systemName: "eye")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(accentGradient)
                .scaleEffect(breathe ? 1.08 : 0.92)
                .animation(
                    .easeInOut(duration: breathDuration).repeatForever(autoreverses: true),
                    value: breathe
                )
        }
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        VStack(spacing: 2) {
            if timeRemaining == 0 {
                // Completion state
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Break Complete")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            } else {
                // Timer number
                Text("\(timeRemaining)")
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(timeRemaining <= 3 ? .green : .primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: timeRemaining)

                Text("seconds remaining")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Breathing Guide

    private var breathingGuide: some View {
        HStack(spacing: 8) {
            // Animated chevron
            Image(systemName: breathPhase.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(accentColor)
                .rotationEffect(.degrees(breathPhase == .inhale ? 0 : 180))
                .animation(.easeInOut(duration: 0.4), value: breathPhase)

            Text(breathPhase.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accentColor)

            // Animated breathing dots
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(accentColor.opacity(0.8))
                        .frame(width: 4, height: 4)
                        .scaleEffect(breathe ? 1.0 : 0.4)
                        .opacity(breathe ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: breathDuration)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.08),
                            value: breathe
                        )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(accentColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(accentColor.opacity(0.15), lineWidth: 0.5)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: breathPhase)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 8) {
            // Progress bar with glow
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.primary.opacity(0.08))

                    // Fill with glow
                    Capsule()
                        .fill(accentGradient)
                        .frame(width: max(4, geo.size.width * progress))
                        .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 0)

                    // Leading dot indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: accentColor.opacity(0.5), radius: 3)
                        .offset(x: max(0, geo.size.width * progress - 4))
                        .opacity(progress > 0.02 ? 1 : 0)
                }
            }
            .frame(height: 6)

            // Progress text
            HStack {
                Text("\(Int((1 - progress) * 100))% complete")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))% remaining")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            // Skip/Done button area
            if timeRemaining == 0 {
                // Done button - prominent
                Button(action: onSkip) {
                    Text("Done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(accentGradient)
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(doneHovered ? 1.02 : 1.0)
                .animation(.easeOut(duration: 0.15), value: doneHovered)
                .onHover { doneHovered = $0 }
            } else if canSkipBreak {
                Button(action: onSkip) {
                    HStack(spacing: 4) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                        Text("Skip")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(skipHovered ? .primary : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(skipHovered ? 0.1 : 0.05))
                    )
                }
                .buttonStyle(.plain)
                .onHover { skipHovered = $0 }
            } else if PreferencesManager.shared.breakSkipDifficulty == "balanced" {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("Skip in \(max(0, 5 - elapsedSeconds))s")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary.opacity(0.6))
            } else {
                // Hardcore - empty space
                Spacer()
                    .frame(width: 80)
            }

            Spacer()

            // Keyboard shortcut hint - macOS style
            HStack(spacing: 3) {
                Image(systemName: "command")
                    .font(.system(size: 9, weight: .medium))
                Text("Esc")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundColor(.secondary.opacity(0.5))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var canSkipBreak: Bool {
        let difficulty = PreferencesManager.shared.breakSkipDifficulty
        switch difficulty {
        case "hardcore": return false
        case "balanced": return elapsedSeconds >= 5
        default: return true
        }
    }

    private func updateTimer() {
        guard let target = targetDate else { return }
        let remaining = target.timeIntervalSinceNow

        if remaining <= 0 {
            timeRemaining = 0
            progress = 0
        } else {
            timeRemaining = Int(ceil(remaining))
            progress = CGFloat(remaining) / CGFloat(duration)
        }

        elapsedSeconds = duration - timeRemaining
    }

    private func startAnimations() {
        targetDate = Date().addingTimeInterval(TimeInterval(duration))

        if reduceMotion {
            appear = true
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appear = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(
                    .easeInOut(duration: breathDuration).repeatForever(autoreverses: true)
                ) {
                    breathe = true
                }
            }

            breathTimer = Timer.scheduledTimer(withTimeInterval: breathDuration, repeats: true) {
                _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.breathPhase = self.breathPhase == .inhale ? .exhale : .inhale
                }
            }
        }
    }

    private func stopTimers() {
        breathTimer?.invalidate()
        breathTimer = nil
    }
}

#Preview {
    SightBreakHUDView(duration: 20, onSkip: {})
}
