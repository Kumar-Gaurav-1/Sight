import SwiftUI

// MARK: - Flash Reminder Settings View

/// Flash Reminder settings screen matching Sight design
struct SightFlashReminderView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = "General"
    @State private var flashDuration: Double = 700
    
    // Computed binding for flash interval in minutes to seconds
    private var flashIntervalBinding: Binding<Int> {
        Binding(
            get: { preferences.blinkReminderIntervalSeconds / 60 },
            set: { preferences.blinkReminderIntervalSeconds = $0 * 60 }
        )
    }
    
    private let tabs = ["General", "Style"]
    
    private let intervalOptions: [(label: String, value: Int)] = [
        ("1 min", 1),
        ("2 min", 2),
        ("5 min", 5),
        ("10 min", 10),
        ("15 min", 15)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Play demo button
            HStack {
                Text("Flash Reminder")
                    .font(SightTheme.titleFont)
                    .foregroundColor(.white)
                
                Spacer()
                
                SightPrimaryButton("Play demo", icon: "play.fill") {
                    // Play demo action
                }
            }
            .padding(.horizontal, SightTheme.sectionSpacing)
            .padding(.top, SightTheme.sectionSpacing)
            .padding(.bottom, 16)
            
            // Tab bar
            SightTabBar(tabs: tabs, selectedTab: $selectedTab)
                .padding(.horizontal, SightTheme.sectionSpacing)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: SightTheme.sectionSpacing) {
                    switch selectedTab {
                    case "General":
                        generalContent
                    case "Style":
                        styleContent
                    default:
                        generalContent
                    }
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(SightTheme.background)
    }
    
    // MARK: - General Tab
    
    private var generalContent: some View {
        VStack(alignment: .leading, spacing: SightTheme.sectionSpacing) {
            // Section header
            Text("General")
                .font(SightTheme.headingFont)
                .foregroundColor(.white)
            
            // Flash Reminder toggle card
            SettingsCard {
                SettingsToggleRow(
                    title: "Flash Reminder",
                    description: "Gentle screen flashes that catch your attention without disrupting your flow. Tailor these gentle alerts to remind you to adjust your posture, sit up straight, or any other habit you want to reinforce.",
                    isOn: $preferences.blinkReminderEnabled
                )
            }
            
            // Flash Interval card
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flash Interval")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("The time between two flash reminders")
                            .font(.system(size: 12))
                            .foregroundColor(SightTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: flashIntervalBinding) {
                        ForEach(intervalOptions, id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .background(SightTheme.elevatedBackground)
                    .cornerRadius(6)
                }
                .padding(SightTheme.cardPadding)
            }
            
            // Flash Duration card
            SettingsCard {
                LargeValueSlider(
                    title: "Flash Duration",
                    description: "The duration in milliseconds that the flash reminder is presented on screen",
                    value: $flashDuration,
                    range: 400...900,
                    step: 50,
                    unit: "milliseconds",
                    tickMarks: [400, 500, 600, 700, 800, 900],
                    showEditButton: true
                )
            }
            
            // Style section header
            Text("Style")
                .font(SightTheme.headingFont)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Style Tab
    
    private var styleContent: some View {
        VStack(alignment: .leading, spacing: SightTheme.sectionSpacing) {
            Text("Style")
                .font(SightTheme.headingFont)
                .foregroundColor(.white)
            
            SettingsCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Flash appearance customization")
                        .font(.system(size: 14))
                        .foregroundColor(SightTheme.secondaryText)
                    
                    // Color options
                    HStack {
                        Text("Flash Color")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            ForEach(["blue", "green", "orange", "white"], id: \.self) { color in
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(SightTheme.cardPadding)
            }
        }
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return SightTheme.accent
        case "green": return SightTheme.success
        case "orange": return SightTheme.warning
        case "white": return .white
        default: return SightTheme.accent
        }
    }
}

#Preview {
    SightFlashReminderView()
        .frame(width: 700, height: 600)
}
