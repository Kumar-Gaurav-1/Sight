import SwiftUI

// MARK: - Breaks Settings View

struct SightBreaksView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            // Segmented picker
            Picker("", selection: $selectedTab) {
                Text("Timing").tag(0)
                Text("Behavior").tag(1)
                Text("Reminders").tag(2)
                Text("Sound").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 16) {
                    if selectedTab == 0 {
                        timingSection
                    } else if selectedTab == 1 {
                        behaviorSection
                    } else if selectedTab == 2 {
                        remindersSection
                    } else {
                        soundSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(SightTheme.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Breaks")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Configure work intervals and break settings")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Current interval badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(preferences.workIntervalSeconds / 60)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                Text("min interval")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Timing Section

    private var timingSection: some View {
        VStack(spacing: 16) {
            // Work interval
            IntervalCard(
                title: "Work Interval",
                subtitle: "Time between breaks",
                value: preferences.workIntervalSeconds / 60,
                unit: "minutes",
                color: .cyan,
                options: [15, 20, 25, 30, 45, 60],
                onChange: { preferences.workIntervalSeconds = $0 * 60 }
            )

            // Break duration
            IntervalCard(
                title: "Break Duration",
                subtitle: "How long each break lasts",
                value: preferences.breakDurationSeconds,
                unit: "seconds",
                color: .green,
                options: [10, 15, 20, 30, 45, 60],
                onChange: { preferences.breakDurationSeconds = $0 }
            )

            // Pre-break warning
            IntervalCard(
                title: "Pre-Break Warning",
                subtitle: "Alert before break starts",
                value: preferences.preBreakSeconds,
                unit: "seconds",
                color: .orange,
                options: [0, 5, 10, 15, 30],
                onChange: { preferences.preBreakSeconds = $0 }
            )
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        VStack(spacing: 20) {
            // Break skip difficulty
            VStack(alignment: .leading, spacing: 12) {
                Text("Break skip difficulty")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    SkipDifficultyCard(
                        mode: .casual,
                        isSelected: preferences.breakSkipDifficulty == "casual"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakSkipDifficulty = "casual"
                        }
                    }

                    SkipDifficultyCard(
                        mode: .balanced,
                        isSelected: preferences.breakSkipDifficulty == "balanced"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakSkipDifficulty = "balanced"
                        }
                    }

                    SkipDifficultyCard(
                        mode: .hardcore,
                        isSelected: preferences.breakSkipDifficulty == "hardcore"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakSkipDifficulty = "hardcore"
                        }
                    }
                }
            }

            // Don't show while typing
            SettingRow(
                icon: "keyboard",
                iconColor: .gray,
                title: "Don't show breaks while I'm typing or dragging",
                subtitle: "Waits until you stop"
            ) {
                Toggle("", isOn: $preferences.dontShowWhileTyping)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            // Long breaks
            SettingRow(
                icon: "arrow.up.right.and.arrow.down.left.rectangle",
                iconColor: .purple,
                title: "Long breaks",
                subtitle: preferences.longBreakEnabled
                    ? "Every \(preferences.longBreakInterval)th break is a \(preferences.longBreakDurationSeconds / 60) mins long break"
                    : "Disabled"
            ) {
                HStack(spacing: 8) {
                    if preferences.longBreakEnabled {
                        Picker("", selection: $preferences.longBreakInterval) {
                            Text("3rd").tag(3)
                            Text("4th").tag(4)
                            Text("5th").tag(5)
                        }
                        .frame(width: 70)

                        Picker("", selection: $preferences.longBreakDurationSeconds) {
                            Text("3 min").tag(180)
                            Text("5 min").tag(300)
                            Text("10 min").tag(600)
                        }
                        .frame(width: 80)
                    }
                    Toggle("", isOn: $preferences.longBreakEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            // Office hours
            SettingRow(
                icon: "clock.badge.checkmark",
                iconColor: .green,
                title: "Office hours",
                subtitle: preferences.officeHoursEnabled
                    ? "\(formatTime(preferences.officeHoursStart)) - \(formatTime(preferences.officeHoursEnd))"
                    : "Disabled"
            ) {
                HStack(spacing: 8) {
                    if preferences.officeHoursEnabled {
                        DatePicker(
                            "", selection: $preferences.officeHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .frame(width: 70)
                        Text("-")
                            .foregroundColor(.secondary)
                        DatePicker(
                            "", selection: $preferences.officeHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .frame(width: 70)
                    }
                    Toggle("", isOn: $preferences.officeHoursEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            InfoCard(
                icon: "info.circle",
                text:
                    "The 20-20-20 rule: Every 20 minutes, look at something 20 feet away for 20 seconds.",
                color: .cyan
            )
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(spacing: 20) {
            // Break reminder toggle
            SettingRow(
                icon: "bell",
                iconColor: .orange,
                title: "Show a reminder before a break appears",
                subtitle: "Gives you time to save work"
            ) {
                Toggle("", isOn: $preferences.showBreakPreview)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if preferences.showBreakPreview {
                HStack(spacing: 12) {
                    Text("Show reminder")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Picker("", selection: $preferences.preBreakSeconds) {
                        Text("30 sec").tag(30)
                        Text("1 min").tag(60)
                        Text("2 min").tag(120)
                    }
                    .frame(width: 80)

                    Text("before the break starts")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
            }

            // Preview cards
            HStack(spacing: 16) {
                // Countdown before break
                VStack(alignment: .leading, spacing: 12) {
                    Text("Countdown before break")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    // Preview card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.5, blue: 0.6),
                                        Color(red: 0.7, green: 0.4, blue: 0.8),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 100)

                        // Countdown preview
                        HStack(spacing: 10) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(10)

                            Text(
                                "Starting break in \(String(format: "%02d", preferences.countdownDuration))"
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }

                    Text("A countdown that displays when a break is about to start")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text("Enabled")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $preferences.countdownEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if preferences.countdownEnabled {
                        HStack {
                            Text("Countdown duration")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Picker("", selection: $preferences.countdownDuration) {
                                Text("3 seconds").tag(3)
                                Text("5 seconds").tag(5)
                                Text("10 seconds").tag(10)
                            }
                            .frame(width: 110)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.regularMaterial)
                )

                // Overtime nudge
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overtime nudge")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    // Preview card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.4, blue: 0.4),
                                        Color(red: 0.7, green: 0.3, blue: 0.7),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 100)

                        // Overtime preview
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                                .padding(10)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("45 minutes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("without a break")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }

                    Text(
                        "Shows how long you've been working past your chosen screen time. Shake to dismiss."
                    )
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                    HStack {
                        Text("Enabled")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $preferences.overtimeNudgeEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if preferences.overtimeNudgeEnabled {
                        HStack {
                            Text("Show even when paused")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Toggle("", isOn: $preferences.overtimeShowWhenPaused)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.regularMaterial)
                )
            }

            // More section
            VStack(alignment: .leading, spacing: 12) {
                Text("More")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                SettingRow(
                    icon: "clock.badge.xmark",
                    iconColor: .orange,
                    title: "Let me \"End break\" early if nearly done",
                    subtitle: "Show button in last 20%"
                ) {
                    Toggle("", isOn: $preferences.endBreakEarly)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                SettingRow(
                    icon: "lock.fill",
                    iconColor: .red,
                    title: "Lock my Mac automatically when a break starts",
                    subtitle: "Forces you to step away"
                ) {
                    Toggle("", isOn: $preferences.lockMacOnBreak)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
        }
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        VStack(spacing: 16) {
            // Break Start Sound
            SoundSettingRow(
                title: "Break Start Sound",
                subtitle: "Play when break begins",
                icon: "bell.badge",
                iconColor: .cyan,
                isEnabled: $preferences.breakStartSoundEnabled,
                selectedSound: $preferences.breakStartSoundType
            )

            // Break End Sound
            SoundSettingRow(
                title: "Break End Sound",
                subtitle: "Play when break completes",
                icon: "bell.badge.fill",
                iconColor: .green,
                isEnabled: $preferences.breakEndSoundEnabled,
                selectedSound: $preferences.breakEndSoundType
            )

            // Nudge Sound
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nudge Sound")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Text("For blink and posture reminders")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $preferences.nudgeSoundType) {
                        ForEach(
                            SoundManager.SoundType.allCases.filter { $0 != .none }, id: \.rawValue
                        ) { sound in
                            Text(sound.rawValue).tag(sound.rawValue)
                        }
                    }
                    .frame(width: 120)

                    Button(action: {
                        if let type = SoundManager.SoundType(rawValue: preferences.nudgeSoundType) {
                            SoundManager.shared.preview(type)
                        }
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 12))
                            .foregroundColor(.purple)
                            .frame(width: 28, height: 28)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                )
            }

            // Volume slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Volume")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(Int(preferences.soundVolume * 100))%")
                        .font(.system(size: 13, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }

                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Slider(value: $preferences.soundVolume, in: 0...1)
                        .accentColor(.cyan)

                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )

            // Sound preview info
            InfoCard(
                icon: "info.circle",
                text:
                    "Tap the speaker icon next to each sound to preview it at the current volume.",
                color: .cyan
            )
        }
    }
}

// MARK: - Sound Setting Row

struct SoundSettingRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isEnabled: Bool
    @Binding var selectedSound: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if isEnabled {
                HStack(spacing: 8) {
                    Picker("", selection: $selectedSound) {
                        ForEach(
                            SoundManager.SoundType.allCases.filter { $0 != .none }, id: \.rawValue
                        ) { sound in
                            HStack {
                                Image(systemName: sound.icon)
                                Text(sound.rawValue)
                            }
                            .tag(sound.rawValue)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: {
                        if let type = SoundManager.SoundType(rawValue: selectedSound) {
                            SoundManager.shared.preview(type)
                        }
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 12))
                            .foregroundColor(iconColor)
                            .frame(width: 32, height: 32)
                            .background(iconColor.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Preview sound")
                }
                .padding(.leading, 36)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Interval Card

struct IntervalCard: View {
    let title: String
    let subtitle: String
    let value: Int
    let unit: String
    let color: Color
    let options: [Int]
    let onChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Value display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(color)

                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Option pills
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: { onChange(option) }) {
                        Text("\(option)")
                            .font(.system(size: 13, weight: value == option ? .semibold : .regular))
                            .foregroundColor(value == option ? .white : .secondary)
                            .frame(minWidth: 36)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(value == option ? color : Color.white.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Skip Difficulty

enum SkipDifficulty: String, CaseIterable {
    case casual
    case balanced
    case hardcore

    var title: String {
        switch self {
        case .casual: return "Casual"
        case .balanced: return "Balanced"
        case .hardcore: return "Hardcore"
        }
    }

    var subtitle: String {
        switch self {
        case .casual: return "Skip anytime"
        case .balanced: return "Skip after a pause"
        case .hardcore: return "No skips allowed"
        }
    }

    var icon: String {
        switch self {
        case .casual: return "chevron.right.2"
        case .balanced: return "circle"
        case .hardcore: return "slash.circle"
        }
    }
}

struct SkipDifficultyCard: View {
    let mode: SkipDifficulty
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    private let gradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.5, blue: 0.3),
            Color(red: 0.95, green: 0.35, blue: 0.55),
            Color(red: 0.7, green: 0.3, blue: 0.7),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Skip button preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradient.opacity(0.95))
                        .frame(height: 80)

                    // Mock skip button
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text("Skip Bre...")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )
                }

                // Labels
                Text(mode.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text(mode.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Setting Row

struct SettingRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            accessory()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.05))
        )
    }
}

#Preview {
    SightBreaksView()
        .frame(width: 600, height: 600)
}
