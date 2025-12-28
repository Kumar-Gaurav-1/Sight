import Combine
import SwiftUI

// MARK: - Break Overlay View

struct SightBreakHUDView: View {
    let duration: Int
    let onSkip: () -> Void

    @State private var timeRemaining: Int
    @State private var progress: CGFloat = 1
    @State private var appear = false
    @State private var breathe = false
    @State private var currentTipIndex = 0
    @State private var targetDate: Date?
    @State private var skipHovered = false
    @State private var tipTimer: Timer?
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathTimer: Timer?

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // Breathing cycle: 4s inhale, 4s exhale
    private let breathDuration: Double = 4.0

    enum BreathPhase: String {
        case inhale = "Breathe in..."
        case exhale = "Breathe out..."
    }

    private let tips = [
        ("eye", "20-20-20 Rule: Every 20 min, look 20 feet away for 20 sec"),
        ("eye.fill", "Focus on a distant object to relax your eye muscles"),
        ("wind", "Take slow, deep breaths to reduce tension"),
        ("figure.stand", "Roll your shoulders back gently"),
        ("hand.raised", "Stretch your hands and wrists"),
        ("sparkles", "Close your eyes for a moment of rest"),
    ]

    init(duration: Int, onSkip: @escaping () -> Void) {
        self.duration = duration
        self.onSkip = onSkip
        _timeRemaining = State(initialValue: duration)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep calming gradient base
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.02, green: 0.04, blue: 0.1),
                        Color.black,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Ultra-thin glass overlay for depth
                Color.black.opacity(0.3)

                VStack(spacing: 0) {
                    Spacer()

                    // Breathing guide text
                    breathingGuide
                        .padding(.bottom, 20)

                    progressRing
                    Spacer().frame(height: 48)
                    tipSection
                    Spacer()
                    skipButton.padding(.bottom, 60)
                }
            }
        }
        .ignoresSafeArea()
        .opacity(appear ? 1 : 0)
        .onAppear { startAnimations() }
        .onDisappear { stopTimers() }
        .onReceive(timer) { _ in
            guard let target = targetDate else { return }
            let remaining = target.timeIntervalSinceNow

            if remaining <= 0 {
                timeRemaining = 0
                progress = 0
            } else {
                timeRemaining = Int(ceil(remaining))
                progress = CGFloat(remaining) / CGFloat(duration)
            }
        }
    }

    // MARK: - Breathing Guide

    private var breathingGuide: some View {
        VStack(spacing: 8) {
            Text(breathPhase.rawValue)
                .font(.system(size: 24, weight: .light, design: .rounded))
                .foregroundColor(.cyan.opacity(0.9))
                .animation(.easeInOut(duration: 0.5), value: breathPhase)

            // Breathing progress indicator
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(breathPhase == .inhale ? Color.cyan : Color.cyan.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(breathe ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: breathDuration)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: breathe
                        )
                }
            }
        }
        .opacity(appear ? 1 : 0)
    }

    private func startAnimations() {
        targetDate = Date().addingTimeInterval(TimeInterval(duration))

        withAnimation(.easeOut(duration: 0.6)) {
            appear = true
        }

        withAnimation(.easeInOut(duration: breathDuration).repeatForever(autoreverses: true)) {
            breathe = true
        }

        // Breathing phase timer - alternate between inhale/exhale
        breathTimer = Timer.scheduledTimer(withTimeInterval: breathDuration, repeats: true) {
            [self] _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                breathPhase = breathPhase == .inhale ? .exhale : .inhale
            }
        }

        // Store timer reference for cleanup - cycle tips every 8 seconds
        tipTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [self] _ in
            guard !tips.isEmpty else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }

    private func stopTimers() {
        tipTimer?.invalidate()
        tipTimer = nil
        breathTimer?.invalidate()
        breathTimer = nil
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            // Outer glow - synced with breathing
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(breathe ? 0.15 : 0.08),
                            Color.cyan.opacity(0.04),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(breathe ? 1.1 : 0.95)

            // Inner breathing circle
            Circle()
                .stroke(
                    Color.cyan.opacity(breathe ? 0.25 : 0.1),
                    lineWidth: 2
                )
                .frame(width: breathe ? 180 : 160, height: breathe ? 180 : 160)
                .animation(
                    .easeInOut(duration: breathDuration).repeatForever(autoreverses: true),
                    value: breathe)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan, Color.cyan.opacity(0.6)], startPoint: .topLeading,
                        endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 12) {
                Text("\(timeRemaining)")
                    .font(.system(size: 80, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("seconds")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
    }

    // MARK: - Tip Section

    private var tipSection: some View {
        let tip = tips[currentTipIndex]

        return HStack(spacing: 14) {
            Image(systemName: tip.0)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 28)

            Text(tip.1)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
        .id(currentTipIndex)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button(action: onSkip) {
            HStack(spacing: 8) {
                Image(systemName: "forward.fill").font(.system(size: 11))
                Text("Skip").font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white.opacity(skipHovered ? 0.9 : 0.5))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.white.opacity(skipHovered ? 0.12 : 0.06)))
        }
        .buttonStyle(.plain)
        .scaleEffect(skipHovered ? 1.02 : 1)
        .onHover { skipHovered = $0 }
        .opacity(appear ? 1 : 0)
    }
}

#Preview {
    SightBreakHUDView(duration: 20, onSkip: {})
}
