import SwiftUI

// MARK: - Sight Theme

/// Centralized theme for Sight-style premium dark UI
enum SightTheme {

    // MARK: - Colors

    /// Main dark background color
    static let background = Color(red: 0.11, green: 0.11, blue: 0.12)

    /// Surface background (between background and card)
    static let surface = Color(red: 0.15, green: 0.15, blue: 0.17)

    /// Sidebar background (slightly different shade)
    static let sidebarBackground = Color(red: 0.13, green: 0.13, blue: 0.14)

    /// Card/container background
    static let cardBackground = Color(red: 0.17, green: 0.17, blue: 0.19)

    /// Elevated card background (for nested elements)
    static let elevatedBackground = Color(red: 0.22, green: 0.22, blue: 0.24)

    /// Primary accent color (blue)
    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)

    /// Accent light variant
    static let accentLight = Color(red: 0.4, green: 0.7, blue: 1.0)

    /// Secondary text color
    static let secondaryText = Color(white: 0.6)

    /// Tertiary text color
    static let tertiaryText = Color(white: 0.45)

    /// Divider color
    static let divider = Color(white: 0.25)

    /// Border color for cards
    static let border = Color(white: 0.2)

    /// Success/active indicator (green)
    static let success = Color(red: 0.2, green: 0.78, blue: 0.35)

    /// Warning indicator (orange)
    static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)

    /// Error/danger (red)
    static let danger = Color(red: 1.0, green: 0.27, blue: 0.23)

    // MARK: - Gradients

    /// Primary accent gradient
    static let accentGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient
    static let successGradient = LinearGradient(
        colors: [success, Color(red: 0.3, green: 0.85, blue: 0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warning gradient
    static let warningGradient = LinearGradient(
        colors: [warning, Color(red: 1.0, green: 0.7, blue: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Glassmorphism background
    static let glassBackground = Color.white.opacity(0.08)

    /// Subtle glow color
    static let glowColor = accent.opacity(0.4)

    // MARK: - Dimensions

    static let sidebarWidth: CGFloat = 240
    static let cardCornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12

    // MARK: - Shadows

    static let shadowSoft = Color.black.opacity(0.2)
    static let shadowMedium = Color.black.opacity(0.35)
    static let shadowHard = Color.black.opacity(0.5)

    // MARK: - Typography

    static let titleFont = Font.system(size: 24, weight: .bold)
    static let headingFont = Font.system(size: 16, weight: .semibold)
    static let bodyFont = Font.system(size: 14)
    static let captionFont = Font.system(size: 12)
    static let smallFont = Font.system(size: 11)
    static let largeValueFont = Font.system(size: 48, weight: .medium)
    static let countdownFont = Font.system(size: 120, weight: .ultraLight, design: .rounded)

    // MARK: - Animation Curves

    /// Snappy spring for buttons
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Smooth spring for transitions
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Bouncy spring for emphasis
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Quick ease for micro-interactions
    static let easeQuick = Animation.easeOut(duration: 0.15)

    /// Standard ease for normal transitions
    static let easeStandard = Animation.easeInOut(duration: 0.25)

    /// Slow ease for dramatic transitions
    static let easeSlow = Animation.easeInOut(duration: 0.5)

    /// Breathing animation (for relaxation)
    static let breathingAnimation = Animation.easeInOut(duration: 4).repeatForever(
        autoreverses: true)

    /// Pulse animation
    static let pulseAnimation = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

    // MARK: - Materials (Liquid Glass)

    /// Light glass material for subtle blur
    static let lightGlass = Material.ultraThinMaterial

    /// Regular glass material for standard blur
    static let regularGlass = Material.regularMaterial

    /// Thick glass material for strong blur
    static let thickGlass = Material.thickMaterial

    /// Thin glass material for barely-there blur
    static let thinGlass = Material.thinMaterial

    // MARK: - Glass Layer Styles

    /// Floating glass card style
    static func floatingGlass(cornerRadius: CGFloat = 16) -> some View {
        EmptyView()
            .background(lightGlass)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }

    /// Inset glass section style
    static func insetGlass(cornerRadius: CGFloat = 12) -> some View {
        EmptyView()
            .background(thinGlass)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

// MARK: - Accessibility Helper

extension SightTheme {
    /// Check if reduced motion is enabled
    @MainActor
    static var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// Get animation respecting reduce motion
    @MainActor
    static func animation(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply Sight card styling
    func sightCard() -> some View {
        self
            .padding(SightTheme.cardPadding)
            .background(SightTheme.cardBackground)
            .cornerRadius(SightTheme.cardCornerRadius)
    }

    /// Apply Sight card with hover effect
    func sightCardHoverable() -> some View {
        self.modifier(HoverableCardModifier())
    }

    /// Apply Sight inner card styling (for nested containers)
    func sightInnerCard() -> some View {
        self
            .padding(SightTheme.cardPadding)
            .background(SightTheme.elevatedBackground)
            .cornerRadius(SightTheme.smallCornerRadius)
    }

    /// Apply background for entire view
    func sightBackground() -> some View {
        self.background(SightTheme.background)
    }

    /// Add soft shadow
    func softShadow() -> some View {
        self.shadow(color: SightTheme.shadowSoft, radius: 8, x: 0, y: 4)
    }

    /// Add glow effect
    func glowEffect(_ color: Color = SightTheme.accent, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }

    /// Enhanced glassmorphism effect with depth
    func glassMorphism(cornerRadius: CGFloat = 16, material: Material = .ultraThinMaterial)
        -> some View
    {
        self
            .background(material)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }

    /// Floating glass card with prominent elevation
    func floatingGlassCard() -> some View {
        self
            .background(.regularMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 30, y: 15)
    }

    /// Inset glass section
    func insetGlass() -> some View {
        self
            .background(.thinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

// MARK: - Hoverable Card Modifier

struct HoverableCardModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(SightTheme.cardPadding)
            .background(isHovered ? SightTheme.elevatedBackground : SightTheme.cardBackground)
            .cornerRadius(SightTheme.cardCornerRadius)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .shadow(
                color: isHovered ? SightTheme.shadowMedium : SightTheme.shadowSoft,
                radius: isHovered ? 12 : 6, x: 0, y: isHovered ? 6 : 3
            )
            .animation(SightTheme.springSnappy, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Custom Button Styles

struct SightPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if configuration.isPressed {
                        SightTheme.accent.opacity(0.8)
                    } else {
                        SightTheme.accentGradient
                    }
                }
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(SightTheme.springSnappy, value: configuration.isPressed)
    }
}

struct SightSecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isHovered
                    ? SightTheme.elevatedBackground.opacity(1.2) : SightTheme.elevatedBackground
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isHovered ? SightTheme.accent.opacity(0.5) : SightTheme.border, lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(SightTheme.springSnappy, value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(SightTheme.easeQuick) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Custom Toggle Style

struct SightToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        configuration.isOn
                            ? SightTheme.accentGradient
                            : LinearGradient(
                                colors: [SightTheme.elevatedBackground], startPoint: .leading,
                                endPoint: .trailing)
                    )
                    .frame(width: 44, height: 26)
                    .shadow(
                        color: configuration.isOn ? SightTheme.accent.opacity(0.3) : .clear,
                        radius: 4, x: 0, y: 0)

                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: SightTheme.shadowSoft, radius: 2, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 9 : -9)
            }
            .animation(SightTheme.springSnappy, value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Progress Ring View

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient

    init(
        progress: Double, lineWidth: CGFloat = 4,
        gradient: LinearGradient = SightTheme.accentGradient
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(SightTheme.springSmooth, value: progress)
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.1),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Animated Checkmark

struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    let color: Color

    init(color: Color = SightTheme.success) {
        self.color = color
    }

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 5, y: 12))
            path.addLine(to: CGPoint(x: 10, y: 17))
            path.addLine(to: CGPoint(x: 20, y: 7))
        }
        .trim(from: 0, to: trimEnd)
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .frame(width: 25, height: 25)
        .onAppear {
            withAnimation(SightTheme.springBouncy.delay(0.1)) {
                trimEnd = 1
            }
        }
    }
}
