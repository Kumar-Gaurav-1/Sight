import SwiftUI

// MARK: - Sight Theme

/// Centralized theme for Sight-style premium dark UI
enum SightTheme {

    // MARK: - Colors

    /// Main background color (System Window Background)
    static let background = Color(nsColor: .windowBackgroundColor)

    /// Surface background (System Control Background)
    static let surface = Color(nsColor: .controlBackgroundColor)

    /// Sidebar background (System Sidebar)
    static let sidebarBackground = Color(nsColor: .windowBackgroundColor)  // Usually transparent/material in modern apps

    /// Card/container background (System Control Background)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)

    /// Elevated card background (System Alternating Content)
    static let elevatedBackground = Color(nsColor: .alternatingContentBackgroundColors[1])

    // MARK: - Dynamic Accent Colors

    /// Primary accent color - dynamic based on user preference (hue slider)
    @MainActor
    static var accent: Color {
        let hue = PreferencesManager.shared.accentHue
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)  // Slightly brighter for visibility
    }

    /// Accent light variant - dynamic based on user preference
    @MainActor
    static var accentLight: Color {
        let hue = PreferencesManager.shared.accentHue
        return Color(hue: hue, saturation: 0.4, brightness: 1.0)
    }

    /// Secondary text color (System Secondary)
    static let secondaryText = Color.secondary

    /// Tertiary text color (System Tertiary)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)

    /// Divider color (System Separator)
    static let divider = Color(nsColor: .separatorColor)

    /// Border color for cards (System Separator/Grid)
    static let border = Color(nsColor: .separatorColor)

    /// Success/active indicator (green)
    static let success = Color.green

    /// Warning indicator (orange)
    static let warning = Color.orange

    /// Error/danger (red)
    static let danger = Color.red

    // MARK: - Gradients

    /// Primary accent gradient - dynamic based on user preference
    @MainActor
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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

    // MARK: - Break Gradient Presets

    /// Available gradient presets for break screen
    enum GradientPreset: String, CaseIterable {
        case sunset = "sunset"
        case ocean = "ocean"
        case forest = "forest"
        case aurora = "aurora"
        case night = "night"

        var colors: [Color] {
            switch self {
            case .sunset:
                return [
                    Color(red: 0.85, green: 0.4, blue: 0.6),
                    Color(red: 0.95, green: 0.6, blue: 0.4),
                ]
            case .ocean:
                return [
                    Color(red: 0.2, green: 0.5, blue: 0.7),
                    Color(red: 0.4, green: 0.7, blue: 0.7),
                ]
            case .forest:
                return [
                    Color(red: 0.2, green: 0.5, blue: 0.3),
                    Color(red: 0.4, green: 0.7, blue: 0.4),
                ]
            case .aurora:
                return [
                    Color(red: 0.3, green: 0.6, blue: 0.5),
                    Color(red: 0.5, green: 0.3, blue: 0.7),
                ]
            case .night:
                return [
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.2, green: 0.2, blue: 0.35),
                ]
            }
        }

        var displayName: String {
            switch self {
            case .sunset: return "Sunset"
            case .ocean: return "Ocean"
            case .forest: return "Forest"
            case .aurora: return "Aurora"
            case .night: return "Night"
            }
        }

        var gradient: LinearGradient {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Get gradient for current user preference
    @MainActor
    static var breakGradient: LinearGradient {
        let presetName = PreferencesManager.shared.breakGradientPreset
        let preset = GradientPreset(rawValue: presetName) ?? .sunset
        return preset.gradient
    }

    /// Glassmorphism background
    static let glassBackground = Color.white.opacity(0.08)

    /// Subtle glow color using accent
    @MainActor
    static var glowColor: Color {
        accent.opacity(0.4)
    }

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
    @MainActor
    func glowEffect(_ color: Color? = nil, radius: CGFloat = 10) -> some View {
        let effectColor = color ?? SightTheme.accent
        return self.shadow(color: effectColor.opacity(0.5), radius: radius, x: 0, y: 0)
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
    let gradient: LinearGradient?

    init(
        progress: Double, lineWidth: CGFloat = 4,
        gradient: LinearGradient? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
    }

    var body: some View {
        let displayGradient = gradient ?? SightTheme.accentGradient
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(displayGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
