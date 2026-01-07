import AppKit
import SwiftUI

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case breaks = "Breaks"
    case wellness = "Wellness"
    case sounds = "Sounds"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .breaks: return "cup.and.saucer.fill"
        case .wellness: return "heart.fill"
        case .sounds: return "speaker.wave.3.fill"
        case .appearance: return "paintbrush.fill"
        case .shortcuts: return "command"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .breaks: return .cyan
        case .wellness: return .pink
        case .sounds: return .orange
        case .appearance: return .purple
        case .shortcuts: return .blue
        case .about: return .green
        }
    }

    var description: String {
        switch self {
        case .general: return "Timer, startup & idle"
        case .breaks: return "Behavior & smart pause"
        case .wellness: return "Blink & posture nudges"
        case .sounds: return "Sound effects & volume"
        case .appearance: return "Menu bar & break screen"
        case .shortcuts: return "Global hotkeys"
        case .about: return "Stats & support"
        }
    }
}

// MARK: - Main Preferences View

public struct SightPreferencesView: View {
    @State private var selectedTab: SettingsTab = .general
    @State private var hoveredTab: SettingsTab?
    @State private var searchText: String = ""

    private var filteredTabs: [SettingsTab] {
        if searchText.isEmpty {
            return SettingsTab.allCases
        }
        return SettingsTab.allCases.filter { tab in
            tab.rawValue.localizedCaseInsensitiveContains(searchText)
                || tab.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    public init() {}

    public var body: some View {
        HSplitView {
            // Enhanced Sidebar
            VStack(spacing: 0) {
                // Header with Search
                VStack(spacing: 12) {
                    // App branding
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: "eye.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sight")
                                .font(.system(size: 15, weight: .semibold))

                            Text("Preferences")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // Search field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))

                        TextField("Search", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)

                Divider().opacity(0.5)

                // Nav Items
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(filteredTabs) { tab in
                            SidebarItem(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                isHovered: hoveredTab == tab
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            }
                            .onHover { hovering in
                                hoveredTab = hovering ? tab : nil
                            }
                        }
                    }
                    .padding(12)
                }

                Divider().opacity(0.5)

                // Footer with timer status
                HStack(spacing: 8) {
                    Circle()
                        .fill(TimerStateMachine.shared.isPaused ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)

                    Text(TimerStateMachine.shared.isPaused ? "Timer Paused" : "Timer Active")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("v1.0.0")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(width: 220)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))

            // Content area
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .breaks:
                    BreaksSettingsView()
                case .wellness:
                    WellnessSettingsView()
                case .sounds:
                    SoundsSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .shortcuts:
                    ShortcutsSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            .id(selectedTab)  // Forces view replacement for clean transition
            .transition(.opacity.animation(.easeInOut(duration: 0.15)))
        }
        .frame(minWidth: 780, minHeight: 580)
    }
}

// MARK: - Sidebar Item

private struct SidebarItem: View {
    let tab: SettingsTab
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon with colored background
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(tab.color.gradient)
                    .frame(width: 28, height: 28)
                    .shadow(color: isSelected ? tab.color.opacity(0.4) : .clear, radius: 4, y: 2)

                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.8))

                Text(tab.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected
                        ? tab.color.opacity(0.12)
                        : (isHovered ? Color.primary.opacity(0.04) : Color.clear)
                )
                .animation(.easeOut(duration: 0.15), value: isSelected)
        )
        .overlay(
            // Left accent bar for selected item
            HStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tab.color)
                        .frame(width: 3)
                        .padding(.vertical, 6)
                }
                Spacer()
            }
        )
        .contentShape(Rectangle())
    }
}

// MARK: - General Settings

private struct GeneralSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @State private var showResetAlert = false

    var body: some View {
        Form {
            Section {
                Picker(selection: $prefs.workIntervalSeconds) {
                    Text("15 minutes").tag(900)
                    Text("20 minutes (Recommended)").tag(1200)
                    Text("25 minutes").tag(1500)
                    Text("30 minutes").tag(1800)
                    Text("45 minutes").tag(2700)
                    Text("60 minutes").tag(3600)
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Break every")
                    }
                }

                Picker(selection: $prefs.breakDurationSeconds) {
                    Text("20 seconds (Recommended)").tag(20)
                    Text("30 seconds").tag(30)
                    Text("45 seconds").tag(45)
                    Text("60 seconds").tag(60)
                    Text("2 minutes").tag(120)
                } label: {
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.blue)
                        Text("Look away for")
                    }
                }
            } header: {
                Text("20-20-20 Rule")
            } footer: {
                Label(
                    "Every 20 minutes, look at something 20 feet away for 20 seconds.",
                    systemImage: "lightbulb"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                Toggle(isOn: $prefs.launchAtLogin) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Launch at login")
                            Text("Start Sight when you log in to your Mac")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $prefs.countdownEnabled) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Show countdown before break")
                            Text("Displays a warning before break starts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Picker(selection: $prefs.idlePauseMinutes) {
                    Text("1 minute").tag(1)
                    Text("2 minutes").tag(2)
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                } label: {
                    HStack {
                        Image(systemName: "moon.zzz")
                            .foregroundColor(.indigo)
                        Text("Pause when idle for")
                    }
                }
            } header: {
                Text("Startup & Behavior")
            } footer: {
                Text("The timer automatically pauses when you step away from your computer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                }
            } footer: {
                Text("Restore all preferences to their default values.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .alert("Reset All Settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                prefs.resetToDefaults()
            }
        } message: {
            Text(
                "This will restore all preferences to their default values. This action cannot be undone."
            )
        }
    }
}

// MARK: - Breaks Settings

private struct BreaksSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        Form {
            Section {
                Picker(selection: $prefs.preBreakSeconds) {
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                    Text("15 seconds").tag(15)
                    Text("30 seconds").tag(30)
                } label: {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.orange)
                        Text("Heads-up notice")
                    }
                }

                Picker(selection: $prefs.breakSkipDifficulty) {
                    Text("Easy").tag("casual")
                    Text("Normal").tag("balanced")
                    Text("Strict").tag("hardcore")
                } label: {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.red)
                        Text("Skip difficulty")
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Break Behavior")
            } footer: {
                Text("Stricter difficulty makes it harder to skip breaks for better adherence.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(isOn: $prefs.meetingDetectionEnabled) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Pause for meetings")
                            Text("Requires Calendar permission")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $prefs.officeHoursEnabled) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Work hours only")
                            Text("Only run during business hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Smart Features")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Wellness Settings

private struct WellnessSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $prefs.blinkReminderEnabled) {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Blink Reminders")
                            Text("Prevent dry eyes from screen use")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if prefs.blinkReminderEnabled {
                    Picker(selection: $prefs.blinkReminderIntervalSeconds) {
                        Text("2 minutes").tag(120)
                        Text("5 minutes").tag(300)
                        Text("10 minutes").tag(600)
                        Text("15 minutes").tag(900)
                        Text("20 minutes").tag(1200)
                    } label: {
                        Text("Remind every")
                    }

                    Toggle(isOn: $prefs.blinkSoundEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.purple)
                            Text("Play sound")
                        }
                    }

                    Button("Preview Blink Nudge") {
                        Renderer.showNudge(type: .blink)
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Eye Health")
            }

            Section {
                Toggle(isOn: $prefs.postureReminderEnabled) {
                    HStack {
                        Image(systemName: "figure.stand")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Posture Reminders")
                            Text("Gentle reminders to sit up straight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if prefs.postureReminderEnabled {
                    Picker(selection: $prefs.postureReminderIntervalSeconds) {
                        Text("15 minutes").tag(900)
                        Text("20 minutes").tag(1200)
                        Text("30 minutes").tag(1800)
                        Text("45 minutes").tag(2700)
                    } label: {
                        Text("Remind every")
                    }

                    Toggle(isOn: $prefs.postureSoundEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.purple)
                            Text("Play sound")
                        }
                    }

                    Button("Preview Posture Nudge") {
                        Renderer.showNudge(type: .posture)
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Physical Wellness")
            }

            Section {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            Renderer.showNudge(type: .blink)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "eye.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                Text("Blink")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Renderer.showNudge(type: .posture)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "figure.stand.line.dotted.figure.stand")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                                Text("Posture")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(spacing: 10) {
                        Button {
                            Renderer.showNudge(type: .miniExercise)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "figure.walk.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.orange)
                                Text("Exercise")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            NudgeOverlayWindowController.shared.showOvertimeNudge(
                                elapsedMinutes: 45)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.red)
                                Text("Overtime")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } header: {
                Text("Preview All Nudges")
            } footer: {
                Label(
                    "Studies show we blink 66% less when looking at screens.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Sounds Settings

private struct SoundsSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $prefs.breakStartSoundEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Break start sound")
                            Text("Chime when break begins")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $prefs.breakEndSoundEnabled) {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Break end sound")
                            Text("Chime when break finishes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Picker(selection: $prefs.soundPair) {
                    Text("Default").tag("Default")
                    Text("Gentle").tag("Gentle")
                    Text("Chime").tag("Chime")
                    Text("Nature").tag("Nature")
                    Text("Minimal").tag("Minimal")
                } label: {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.purple)
                        Text("Sound style")
                    }
                }

                Button("Preview Sound") {
                    SoundManager.shared.playBreakStart()
                }
                .buttonStyle(.bordered)
            } header: {
                Text("Break Sounds")
            }

            Section {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                    Text("Volume")
                    Spacer()
                    Text("\(Int(prefs.soundVolume * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $prefs.soundVolume, in: 0...1)
            } header: {
                Text("Volume")
            } footer: {
                Text("Choose sound styles that are pleasant but noticeable.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance Settings

private struct AppearanceSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $prefs.showInMenuBar) {
                    HStack {
                        Image(systemName: "menubar.rectangle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Show in menu bar")
                            Text("Display Sight icon in the menu bar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $prefs.showTimerInMenuBar) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Show countdown timer")
                            Text("Display time remaining in menu bar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Menu Bar")
            }

            Section {
                Picker(selection: $prefs.breakBackgroundType) {
                    Text("Blur").tag("blur")
                    Text("Gradient").tag("gradient")
                    Text("Solid").tag("solid")
                } label: {
                    HStack {
                        Image(systemName: "rectangle.fill")
                            .foregroundColor(.purple)
                        Text("Background style")
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Break Screen")
            }

            Section {
                VStack(spacing: 16) {
                    // Screen mockup with position grid
                    VStack(spacing: 4) {
                        // Monitor screen
                        ZStack {
                            // Screen background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .frame(width: 220, height: 140)

                            // Screen border
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                                .frame(width: 220, height: 140)

                            // Position grid
                            VStack(spacing: 24) {
                                // Top row
                                HStack(spacing: 50) {
                                    PositionButton(
                                        position: "topLeft", label: "↖",
                                        current: prefs.breakAlertPosition
                                    ) { prefs.breakAlertPosition = "topLeft" }

                                    PositionButton(
                                        position: "topCenter", label: "↑",
                                        current: prefs.breakAlertPosition
                                    ) { prefs.breakAlertPosition = "topCenter" }

                                    PositionButton(
                                        position: "topRight", label: "↗",
                                        current: prefs.breakAlertPosition
                                    ) { prefs.breakAlertPosition = "topRight" }
                                }

                                // Center
                                PositionButton(
                                    position: "center", label: "●",
                                    current: prefs.breakAlertPosition
                                ) { prefs.breakAlertPosition = "center" }

                                // Bottom row
                                HStack(spacing: 50) {
                                    PositionButton(
                                        position: "bottomLeft", label: "↙",
                                        current: prefs.breakAlertPosition
                                    ) { prefs.breakAlertPosition = "bottomLeft" }

                                    PositionButton(
                                        position: "bottomCenter", label: "↓",
                                        current: prefs.breakAlertPosition
                                    ) { prefs.breakAlertPosition = "bottomCenter" }

                                    PositionButton(
                                        position: "bottomRight", label: "↘",
                                        current: prefs.breakAlertPosition
                                    ) { prefs.breakAlertPosition = "bottomRight" }
                                }
                            }
                        }

                        // Monitor stand
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 20, height: 12)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 60, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    Button("Preview Break Screen") {
                        Renderer.showBreak(durationSeconds: 5)
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Break Alert Position")
            } footer: {
                Text("Choose where the break reminder appears on your screen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Position Button

private struct PositionButton: View {
    let position: String
    let label: String
    let current: String
    let action: () -> Void

    @State private var isHovered = false

    private var isSelected: Bool {
        current == position
    }

    private var positionName: String {
        switch position {
        case "topLeft": return "Top Left"
        case "topCenter": return "Top Center"
        case "topRight": return "Top Right"
        case "center": return "Center"
        case "bottomLeft": return "Bottom Left"
        case "bottomCenter": return "Bottom Center"
        case "bottomRight": return "Bottom Right"
        default: return position
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isSelected
                                ? Color.accentColor : Color.primary.opacity(isHovered ? 0.1 : 0.05))
                )
        }
        .buttonStyle(.plain)
        .help(positionName)
        .accessibilityLabel(positionName)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Shortcuts Settings

private struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                ShortcutRow(
                    icon: "playpause", color: .green, label: "Start/Pause Timer", keys: "⌘⇧S")
                ShortcutRow(
                    icon: "cup.and.saucer", color: .blue, label: "Take Break Now", keys: "⌘⇧B")
                ShortcutRow(icon: "forward.end", color: .orange, label: "Skip Break", keys: "⌘⇧X")
            } header: {
                Text("Timer Controls")
            }

            Section {
                ShortcutRow(icon: "gearshape", color: .gray, label: "Open Preferences", keys: "⌘,")
                ShortcutRow(icon: "eye", color: .purple, label: "Show/Hide Menu", keys: "⌘⇧E")
                ShortcutRow(icon: "power", color: .red, label: "Quit Sight", keys: "⌘Q")
            } header: {
                Text("App Controls")
            } footer: {
                Label(
                    "Shortcuts work globally, even when Sight is in the background.",
                    systemImage: "globe"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutRow: View {
    let icon: String
    let color: Color
    let label: String
    let keys: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
            Spacer()
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
        }
    }
}

// MARK: - About Settings

private struct AboutSettingsView: View {
    @State private var glowOpacity: Double = 0.3
    @ObservedObject var adherence = AdherenceManager.shared

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.blue.opacity(glowOpacity), .clear], center: .center,
                                    startRadius: 20, endRadius: 60)
                            )
                            .frame(width: 80, height: 80)
                            .blur(radius: 10)

                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 2)

                    VStack(spacing: 2) {
                        Text("Sight")
                            .font(.title3.bold())
                        Text("Version 1.0.0 (Build 1)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.6
                    }
                }
            }

            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Breaks Completed")
                    Spacer()
                    Text("\(adherence.totalBreaksCompleted)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.blue)
                    Text("Weekly Score")
                    Spacer()
                    Text("\(Int(adherence.weeklyScore))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Current Streak")
                    Spacer()
                    Text("\(adherence.currentStreak) days")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Your Statistics")
            }

            Section {
                Link(destination: URL(string: "https://sight.app")!) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Visit Website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundColor(.primary)

                Link(destination: URL(string: "mailto:support@sight.app")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.green)
                        Text("Contact Support")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundColor(.primary)

                Link(destination: URL(string: "https://twitter.com/SightApp")!) {
                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(.cyan)
                        Text("Follow on X")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundColor(.primary)

                Link(destination: URL(string: "https://sight.app/privacy")!) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.purple)
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundColor(.primary)
            } header: {
                Text("Resources")
            }

            Section {
                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Sight")
                    }
                    .frame(maxWidth: .infinity)
                }
            } footer: {
                Text("© 2024 Sight. Made with ❤️ for your eyes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SightPreferencesView()
}
