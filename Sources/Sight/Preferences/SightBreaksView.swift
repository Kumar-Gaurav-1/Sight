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
                Text("Sound").tag(2)
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
        VStack(spacing: 16) {
            SettingRow(
                icon: "forward",
                iconColor: .orange,
                title: "Allow Skip",
                subtitle: "Let users skip breaks"
            ) {
                Toggle("", isOn: $preferences.allowSkipBreak)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            SettingRow(
                icon: "clock.arrow.circlepath",
                iconColor: .purple,
                title: "Allow Postpone",
                subtitle: "Delay break by 5 minutes"
            ) {
                Toggle("", isOn: $preferences.allowPostponeBreak)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            SettingRow(
                icon: "pause.circle",
                iconColor: .blue,
                title: "Pause When Idle",
                subtitle: "Stop timer during inactivity"
            ) {
                Picker("", selection: $preferences.idlePauseMinutes) {
                    Text("1 min").tag(1)
                    Text("2 min").tag(2)
                    Text("5 min").tag(5)
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }
            
            InfoCard(
                icon: "info.circle",
                text: "The 20-20-20 rule: Every 20 minutes, look at something 20 feet away for 20 seconds.",
                color: .cyan
            )
        }
    }
    
    // MARK: - Sound Section
    
    private var soundSection: some View {
        VStack(spacing: 16) {
            SettingRow(
                icon: "bell.badge",
                iconColor: .cyan,
                title: "Break Start Sound",
                subtitle: "Play when break begins"
            ) {
                Toggle("", isOn: $preferences.breakStartSoundEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            SettingRow(
                icon: "bell.badge.fill",
                iconColor: .green,
                title: "Break End Sound",
                subtitle: "Play when break completes"
            ) {
                Toggle("", isOn: $preferences.breakEndSoundEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            // Volume slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Volume")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(preferences.soundVolume * 100))%")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
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
        }
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

#Preview {
    SightBreaksView()
        .frame(width: 600, height: 600)
}
