import SwiftUI

// MARK: - About View

/// Premium about screen with app info, credits, and links
struct SightAboutView: View {
    @State private var logoHovered = false
    @State private var showVersion = false

    private let version =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("About")
                .font(SightTheme.titleFont)
                .foregroundColor(.white)
                .padding(.horizontal, SightTheme.sectionSpacing)
                .padding(.top, SightTheme.sectionSpacing)
                .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 24) {
                    // App Logo & Info
                    appInfoCard

                    // Features
                    featuresCard

                    // Credits
                    creditsCard

                    // Links
                    linksCard

                    // Legal
                    legalSection
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(SightTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showVersion = true
            }
        }
    }

    // MARK: - App Info Card

    private var appInfoCard: some View {
        VStack(spacing: 20) {
            // Logo
            ZStack {
                // Glow
                Circle()
                    .fill(SightTheme.accent.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .scaleEffect(logoHovered ? 1.2 : 1)

                // Icon container - use custom AppIcon
                if let iconImage = NSImage(named: "AppIcon") {
                    Image(nsImage: iconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .shadow(color: SightTheme.accent.opacity(0.5), radius: 15)
                        .scaleEffect(logoHovered ? 1.1 : 1)
                        .onHover { logoHovered = $0 }
                } else {
                    // Fallback to gradient icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SightTheme.accent,
                                        SightTheme.accent.opacity(0.7),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "eye.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(logoHovered ? 1.1 : 1)
                    .onHover { logoHovered = $0 }
                }
            }

            // App name
            VStack(spacing: 8) {
                Text("Sight")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Eye Care & Break Reminder")
                    .font(.system(size: 14))
                    .foregroundColor(SightTheme.secondaryText)

                // Version
                HStack(spacing: 8) {
                    Text("Version \(version)")
                        .font(.system(size: 12, weight: .medium))
                    Text("•")
                    Text("Build \(build)")
                        .font(.system(size: 12))
                }
                .foregroundColor(SightTheme.tertiaryText)
                .opacity(showVersion ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(SightTheme.cardBackground)
        )
    }

    // MARK: - Features Card

    private var featuresCard: some View {
        EnhancedSettingsCard(
            icon: "sparkles",
            iconColor: SightTheme.accent,
            title: "Features",
            delay: 0
        ) {
            VStack(spacing: 0) {
                FeatureRow(
                    icon: "timer", title: "20-20-20 Rule",
                    description: "Science-backed eye protection")
                Divider().background(Color.white.opacity(0.05))
                FeatureRow(
                    icon: "bell.badge", title: "Smart Reminders",
                    description: "Blink & posture notifications")
                Divider().background(Color.white.opacity(0.05))
                FeatureRow(
                    icon: "calendar", title: "Meeting Detection",
                    description: "Auto-pause during meetings")
                Divider().background(Color.white.opacity(0.05))
                FeatureRow(
                    icon: "trophy", title: "Gamification",
                    description: "Earn badges for healthy habits")
                Divider().background(Color.white.opacity(0.05))
                FeatureRow(
                    icon: "chart.bar", title: "Statistics", description: "Track your break history")
            }
        }
    }

    // MARK: - Credits Card

    private var creditsCard: some View {
        EnhancedSettingsCard(
            icon: "heart.fill",
            iconColor: .pink,
            title: "Made with ❤️",
            delay: 0.05
        ) {
            VStack(spacing: 12) {
                Text("Built for healthier screen time")
                    .font(.system(size: 14))
                    .foregroundColor(SightTheme.secondaryText)

                Text(
                    "Designed to help you take care of your eyes while working on what matters to you."
                )
                .font(.system(size: 13))
                .foregroundColor(SightTheme.tertiaryText)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
    }

    // MARK: - Links Card

    private var linksCard: some View {
        EnhancedSettingsCard(
            icon: "link",
            iconColor: SightTheme.success,
            title: "Links",
            delay: 0.1
        ) {
            VStack(spacing: 0) {
                LinkRow(icon: "globe", title: "Website", url: "https://sight.app")
                Divider().background(Color.white.opacity(0.05))
                LinkRow(icon: "book", title: "Documentation", url: "https://docs.sight.app")
                Divider().background(Color.white.opacity(0.05))
                LinkRow(
                    icon: "exclamationmark.bubble", title: "Report Issue",
                    url: "https://github.com/sight/issues")
                Divider().background(Color.white.opacity(0.05))
                LinkRow(
                    icon: "star", title: "Rate on App Store",
                    url: "https://apps.apple.com/app/sight")
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("© \(Calendar.current.component(.year, from: Date())) Sight. All rights reserved.")
                .font(.system(size: 11))
                .foregroundColor(SightTheme.tertiaryText)

            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    if let url = URL(string: "https://sight.app/privacy") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)

                Text("•")

                Button("Terms of Service") {
                    if let url = URL(string: "https://sight.app/terms") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 11))
            .foregroundColor(SightTheme.tertiaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(SightTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(SightTheme.tertiaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Link Row

struct LinkRow: View {
    let icon: String
    let title: String
    let url: String

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(SightTheme.accent)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundColor(SightTheme.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    SightAboutView()
        .frame(width: 700, height: 700)
}
