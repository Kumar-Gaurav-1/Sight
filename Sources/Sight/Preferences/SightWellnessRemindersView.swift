import SwiftUI

// MARK: - Wellness Reminders View

struct SightWellnessRemindersView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            // Segmented picker
            Picker("", selection: $selectedTab) {
                Text("Blink").tag(0)
                Text("Posture").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    if selectedTab == 0 {
                        blinkSection
                    } else {
                        postureSection
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Wellness Reminders")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Gentle nudges to protect your eyes and posture")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Blink Section
    
    private var blinkSection: some View {
        VStack(spacing: 16) {
            // Toggle card
            SettingRow(
                icon: "eye",
                iconColor: .cyan,
                title: "Blink Reminders",
                subtitle: "Remind you to blink regularly"
            ) {
                Toggle("", isOn: $preferences.blinkReminderEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            if preferences.blinkReminderEnabled {
                // Interval
                IntervalPickerCard(
                    title: "Reminder Interval",
                    value: preferences.blinkReminderIntervalSeconds,
                    options: [
                        (60, "1 min"),
                        (120, "2 min"),
                        (300, "5 min"),
                        (600, "10 min")
                    ],
                    onChange: { preferences.blinkReminderIntervalSeconds = $0 }
                )
                
                // Sound
                SettingRow(
                    icon: "speaker.wave.2",
                    iconColor: .cyan,
                    title: "Play Sound",
                    subtitle: "Audio notification"
                ) {
                    Toggle("", isOn: $preferences.blinkSoundEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            
            // Info
            InfoCard(
                icon: "info.circle",
                text: "Screen use can reduce your blink rate by 66%. Regular blinking keeps eyes moisturized.",
                color: .cyan
            )
        }
    }
    
    // MARK: - Posture Section
    
    private var postureSection: some View {
        VStack(spacing: 16) {
            // Toggle card
            SettingRow(
                icon: "figure.stand",
                iconColor: .orange,
                title: "Posture Reminders",
                subtitle: "Check your sitting position"
            ) {
                Toggle("", isOn: $preferences.postureReminderEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            if preferences.postureReminderEnabled {
                // Interval
                IntervalPickerCard(
                    title: "Reminder Interval",
                    value: preferences.postureReminderIntervalSeconds,
                    options: [
                        (900, "15 min"),
                        (1800, "30 min"),
                        (2700, "45 min"),
                        (3600, "1 hour")
                    ],
                    onChange: { preferences.postureReminderIntervalSeconds = $0 }
                )
                
                // Sound
                SettingRow(
                    icon: "speaker.wave.2",
                    iconColor: .orange,
                    title: "Play Sound",
                    subtitle: "Audio notification"
                ) {
                    Toggle("", isOn: $preferences.postureSoundEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            
            // Info
            InfoCard(
                icon: "info.circle",
                text: "Poor posture leads to back pain and fatigue. Regular checks build healthy habits.",
                color: .orange
            )
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
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
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

// MARK: - Interval Picker Card

struct IntervalPickerCard: View {
    let title: String
    let value: Int
    let options: [(Int, String)]
    let onChange: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(options, id: \.0) { option in
                    Button(action: { onChange(option.0) }) {
                        Text(option.1)
                            .font(.system(size: 13, weight: value == option.0 ? .semibold : .regular))
                            .foregroundColor(value == option.0 ? .white : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(value == option.0 ? Color.accentColor : Color.white.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .foregroundColor(color.opacity(0.8))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
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
    SightWellnessRemindersView()
        .frame(width: 600, height: 500)
}
