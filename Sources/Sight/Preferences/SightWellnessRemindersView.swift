import SwiftUI

// MARK: - Wellness Reminders View

struct SightWellnessRemindersView: View {
    @ObservedObject private var preferences = PreferencesManager.shared

    var body: some View {
        Form {
            // MARK: - Blink Reminders Section
            Section {
                Toggle(isOn: $preferences.blinkReminderEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Blink Reminders")
                            Text("Prevent dry eyes from prolonged screen use")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if preferences.blinkReminderEnabled {
                    Picker(
                        selection: Binding(
                            get: { preferences.blinkReminderIntervalSeconds / 60 },
                            set: { preferences.blinkReminderIntervalSeconds = $0 * 60 }
                        )
                    ) {
                        Text("2 minutes").tag(2)
                        Text("3 minutes").tag(3)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                    } label: {
                        Text("Remind every")
                    }

                    Toggle(isOn: $preferences.blinkSoundEnabled) {
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
            } footer: {
                Label(
                    "Studies show we blink 66% less when looking at screens.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // MARK: - Posture Reminders Section
            Section {
                Toggle(isOn: $preferences.postureReminderEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.stand")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Posture Reminders")
                            Text("Gentle nudges to sit up straight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if preferences.postureReminderEnabled {
                    Picker(
                        selection: Binding(
                            get: { preferences.postureReminderIntervalSeconds / 60 },
                            set: { preferences.postureReminderIntervalSeconds = $0 * 60 }
                        )
                    ) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                        Text("25 minutes").tag(25)
                        Text("30 minutes").tag(30)
                    } label: {
                        Text("Remind every")
                    }

                    Toggle(isOn: $preferences.postureSoundEnabled) {
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

            // MARK: - Common Settings
            Section {
                Toggle(isOn: $preferences.dimScreenOnReminder) {
                    HStack {
                        Image(systemName: "sun.min")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Dim screen on reminder")
                            Text("Reduces brightness to draw attention")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.showRemindersDuringPauses) {
                    HStack {
                        Image(systemName: "pause.circle")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Show during pauses")
                            Text("Continue reminders during meetings & videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.resetTimersAfterBreak) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Reset timers after break")
                            Text("Start fresh reminder cycle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Advanced")
            }

            // MARK: - Quick Preview Section
            Section {
                HStack(spacing: 16) {
                    Button {
                        Renderer.showNudge(type: .blink)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.blue)
                            Text("Blink")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Renderer.showNudge(type: .posture)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "figure.stand.line.dotted.figure.stand")
                                .font(.system(size: 28))
                                .foregroundStyle(.green)
                            Text("Posture")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Renderer.showNudge(type: .miniExercise)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "figure.walk.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.orange)
                            Text("Exercise")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Preview All Nudges")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SightWellnessRemindersView()
        .frame(width: 500, height: 700)
}
