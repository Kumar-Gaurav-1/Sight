import SwiftUI

// MARK: - Enhanced Settings Components
// These components match the "Premium" look used in other tabs.
// Ideally, these should be replaced by native Forms over time.

struct EnhancedSettingsCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let delay: Double
    @ViewBuilder let content: Content

    @State private var isVisible = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(SightTheme.divider)
                .padding(.horizontal, 16)

            content
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHovered ? SightTheme.cardBackground.opacity(1.1) : SightTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(isHovered ? 0.08 : 0.03), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.98)
        .opacity(isVisible ? 1 : 0)
        .animation(SightTheme.springSmooth.delay(delay), value: isVisible)
        .onHover { isHovered = $0 }
        .onAppear { isVisible = true }
    }
}

struct EnhancedToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SightTheme.secondaryText)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(SightTheme.tertiaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SightToggleStyle())
                .labelsHidden()
        }
        .padding(16)
    }
}

struct EnhancedNumberRow: View {
    let title: String
    let description: String
    @Binding var value: Int
    let unit: String
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(SightTheme.tertiaryText)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: { if value > range.lowerBound { value -= 1 } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SightTheme.secondaryText)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 30)
                    .monospacedDigit()

                Button(action: { if value < range.upperBound { value += 1 } }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SightTheme.secondaryText)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(SightTheme.tertiaryText)
            }
        }
        .padding(16)
    }
}

struct DayPillToggle: View {
    let day: String
    @Binding var isActive: Bool

    @State private var isHovered = false

    var body: some View {
        Button(action: { isActive.toggle() }) {
            Text(day)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .white : SightTheme.tertiaryText)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isActive ? SightTheme.accent : Color.white.opacity(0.08))
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct QuickActionRow: View {
    let action: String
    let description: String

    var body: some View {
        HStack {
            Text(action)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(SightTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SightTheme.accent.opacity(0.15))
                .cornerRadius(6)

            Text(description)
                .font(.system(size: 13))
                .foregroundColor(SightTheme.secondaryText)

            Spacer()
        }
    }
}
