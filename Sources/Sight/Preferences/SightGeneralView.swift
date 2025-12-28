import SwiftUI

// MARK: - General Settings View

/// Premium general settings screen
struct SightGeneralView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = "General"
    @State private var resetConfirmation = false

    private let tabs = ["General", "Working Hours", "Menu Bar"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with gradient
            header

            // Tab bar
            EnhancedTabBar(tabs: tabs, selectedTab: $selectedTab)
                .padding(.horizontal, SightTheme.sectionSpacing)

            // Content with transition
            ScrollView {
                VStack(alignment: .leading, spacing: SightTheme.sectionSpacing) {
                    switch selectedTab {
                    case "General":
                        generalContent
                    case "Working Hours":
                        workingHoursContent
                    case "Menu Bar":
                        menuBarContent
                    default:
                        generalContent
                    }
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(SightTheme.background)
    }

    // MARK: - Header

    private var statusColor: Color {
        if WorkHoursManager.shared.shouldPauseForSchedule { return .orange }
        if SmartPauseManager.shared.shouldPause { return .yellow }
        return SightTheme.success
    }

    private var statusText: String {
        if let reason = WorkHoursManager.shared.pauseReason { return reason }
        if SmartPauseManager.shared.shouldPause { return "Smart Pause" }
        return "Active"
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("General")
                    .font(SightTheme.titleFont)
                    .foregroundColor(.white)

                Text("Configure app behavior and preferences")
                    .font(.system(size: 13))
                    .foregroundColor(SightTheme.secondaryText)
            }

            Spacer()

            // Status indicator - reactive
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SightTheme.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .padding(.horizontal, SightTheme.sectionSpacing)
        .padding(.top, SightTheme.sectionSpacing)
        .padding(.bottom, 16)
    }

    // MARK: - General Tab

    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Launch section
            EnhancedSettingsCard(
                icon: "power",
                iconColor: SightTheme.accent,
                title: "Startup",
                delay: 0
            ) {
                EnhancedToggleRow(
                    title: "Launch at Login",
                    description: "Start Sight automatically when you log in",
                    icon: "laptopcomputer",
                    isOn: $preferences.launchAtLogin
                )
            }

            // Idle section
            EnhancedSettingsCard(
                icon: "clock.arrow.circlepath",
                iconColor: SightTheme.warning,
                title: "Idle Detection",
                delay: 0.05
            ) {
                VStack(spacing: 0) {
                    EnhancedNumberRow(
                        title: "Pause timer after",
                        description: "Pause when inactive",
                        value: $preferences.idlePauseMinutes,
                        unit: "min",
                        range: 1...30
                    )

                    Divider()
                        .background(SightTheme.divider)
                        .padding(.horizontal, 16)

                    EnhancedNumberRow(
                        title: "Reset timer after",
                        description: "Reset to 0 when idle",
                        value: $preferences.idleResetMinutes,
                        unit: "min",
                        range: 1...60
                    )
                }
            }

            // Notifications section
            EnhancedSettingsCard(
                icon: "bell.badge",
                iconColor: SightTheme.success,
                title: "Notifications",
                delay: 0.1
            ) {
                VStack(spacing: 0) {
                    EnhancedToggleRow(
                        title: "Break Reminders",
                        description: "Show notification before breaks",
                        icon: "bell",
                        isOn: $preferences.soundEnabled
                    )

                    Divider()
                        .background(SightTheme.divider)
                        .padding(.horizontal, 16)

                    EnhancedToggleRow(
                        title: "Sound Effects",
                        description: "Play sounds for break events",
                        icon: "speaker.wave.2",
                        isOn: $preferences.breakStartSoundEnabled
                    )
                }
            }

            // Reset section
            EnhancedSettingsCard(
                icon: "arrow.counterclockwise",
                iconColor: SightTheme.danger,
                title: "Reset",
                delay: 0.15
            ) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reset to Defaults")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text("Restore all settings to original values")
                            .font(.system(size: 12))
                            .foregroundColor(SightTheme.secondaryText)
                    }

                    Spacer()

                    Button(action: {
                        resetConfirmation = true
                    }) {
                        Text("Reset All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(SightTheme.danger.opacity(0.8))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .alert("Reset Settings?", isPresented: $resetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    preferences.resetToDefaults()
                }
            } message: {
                Text("This will restore all settings to their default values.")
            }
        }
    }

    // MARK: - Working Hours Tab

    private var workingHoursContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            EnhancedSettingsCard(
                icon: "calendar.badge.clock",
                iconColor: SightTheme.accent,
                title: "Schedule",
                delay: 0
            ) {
                VStack(spacing: 0) {
                    EnhancedToggleRow(
                        title: "Enable Working Hours",
                        description: "Only remind during configured times",
                        icon: "clock",
                        isOn: $preferences.quietHoursEnabled
                    )

                    if preferences.quietHoursEnabled {
                        Divider()
                            .background(SightTheme.divider)
                            .padding(.horizontal, 16)

                        // Time picker row
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active Hours")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text(
                                    formatHoursRange(
                                        start: preferences.quietHoursStart,
                                        end: preferences.quietHoursEnd)
                                )
                                .font(.system(size: 12))
                                .foregroundColor(SightTheme.secondaryText)
                            }

                            Spacer()

                            // Hour pickers
                            HStack(spacing: 8) {
                                Picker("", selection: $preferences.quietHoursStart) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(formatHour(hour)).tag(hour)
                                    }
                                }
                                .frame(width: 75)

                                Text("to")
                                    .font(.system(size: 12))
                                    .foregroundColor(SightTheme.secondaryText)

                                Picker("", selection: $preferences.quietHoursEnd) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(formatHour(hour)).tag(hour)
                                    }
                                }
                                .frame(width: 75)
                            }
                        }
                        .padding(16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            EnhancedSettingsCard(
                icon: "calendar",
                iconColor: SightTheme.success,
                title: "Active Days",
                delay: 0.05
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select which days Sight is active")
                        .font(.system(size: 12))
                        .foregroundColor(SightTheme.secondaryText)

                    HStack(spacing: 8) {
                        let days = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
                        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                            DayPillToggle(day: day, isActive: $preferences.activeDays[index])
                        }
                    }
                }
                .padding(16)
            }

            // Smart Pause Settings
            EnhancedSettingsCard(
                icon: "pause.circle",
                iconColor: .purple,
                title: "Smart Pause",
                delay: 0.1
            ) {
                VStack(spacing: 0) {
                    EnhancedToggleRow(
                        title: "Pause for Fullscreen Apps",
                        description: "Don't interrupt videos, games, or presentations",
                        icon: "rectangle.fill.on.rectangle.fill",
                        isOn: $preferences.pauseForFullscreenApps
                    )

                    Divider()
                        .background(SightTheme.divider)
                        .padding(.horizontal, 16)

                    EnhancedToggleRow(
                        title: "Pause During Meetings",
                        description: "Detect calendar events automatically",
                        icon: "video.fill",
                        isOn: $preferences.meetingDetectionEnabled
                    )
                }
            }
        }
    }

    // MARK: - Menu Bar Tab

    private var menuBarContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            EnhancedSettingsCard(
                icon: "menubar.rectangle",
                iconColor: SightTheme.accent,
                title: "Menu Bar",
                delay: 0
            ) {
                VStack(spacing: 0) {
                    EnhancedToggleRow(
                        title: "Show in Menu Bar",
                        description: "Display Sight icon for quick access",
                        icon: "eye",
                        isOn: $preferences.showInMenuBar
                    )

                    Divider()
                        .background(SightTheme.divider)
                        .padding(.horizontal, 16)

                    EnhancedToggleRow(
                        title: "Show Timer",
                        description: "Display countdown in menu bar",
                        icon: "timer",
                        isOn: $preferences.showTimerInMenuBar
                    )
                }
            }

            EnhancedSettingsCard(
                icon: "hand.point.up.left",
                iconColor: SightTheme.warning,
                title: "Quick Actions",
                delay: 0.05
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    QuickActionRow(action: "Click", description: "Open dashboard")
                    QuickActionRow(action: "⌥ Click", description: "Toggle timer")
                    QuickActionRow(action: "Right Click", description: "Context menu")
                }
                .padding(16)
            }
        }
    }

    // MARK: - Helper Functions

    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour):00 \(period)"
    }

    private func formatHoursRange(start: Int, end: Int) -> String {
        "\(formatHour(start)) - \(formatHour(end))"
    }
}

// MARK: - Enhanced Tab Bar

struct EnhancedTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.self) { tab in
                TabButton(title: tab, isSelected: selectedTab == tab) {
                    withAnimation(SightTheme.springSnappy) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : SightTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SightTheme.accent)
                        } else if isHovered {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Enhanced Settings Card

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

// MARK: - Enhanced Toggle Row

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

// MARK: - Enhanced Number Row

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

// MARK: - Day Pill Toggle

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

// MARK: - Quick Action Row

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

#Preview {
    SightGeneralView()
        .frame(width: 700, height: 600)
}
