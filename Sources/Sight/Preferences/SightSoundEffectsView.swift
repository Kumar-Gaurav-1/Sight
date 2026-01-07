import AVFoundation
import SwiftUI

// MARK: - Sound Effects View

struct SightSoundEffectsView: View {
    @ObservedObject private var preferences = PreferencesManager.shared

    var body: some View {
        Form {
            // MARK: - Break Sounds Section
            Section {
                Picker(selection: $preferences.soundPair) {
                    Text("Default").tag("Default")
                    Text("Gentle").tag("Gentle")
                    Text("Chime").tag("Chime")
                    Text("Bell").tag("Bell")
                    Text("Nature").tag("Nature")
                    Text("Minimal").tag("Minimal")
                } label: {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.purple)
                        Text("Sound style")
                    }
                }

                Toggle(isOn: $preferences.breakStartSoundEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Break start sound")
                            Text("Play when break begins")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.breakEndSoundEnabled) {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Break end sound")
                            Text("Play when break finishes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                    Text("Volume")
                    Spacer()
                    Text("\(Int(preferences.soundVolume * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 40)
                }

                Slider(value: $preferences.soundVolume, in: 0...1)

                Button("Preview Break Sound") {
                    SoundManager.shared.playBreakStart()
                }
                .buttonStyle(.bordered)
            } header: {
                Text("Break Sounds")
            }

            // MARK: - Wellness Sounds Section
            Section {
                Toggle(isOn: $preferences.postureSoundEnabled) {
                    HStack {
                        Image(systemName: "figure.stand")
                            .foregroundColor(.green)
                        Text("Posture reminder sound")
                    }
                }

                Toggle(isOn: $preferences.blinkSoundEnabled) {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                        Text("Blink reminder sound")
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.1.fill")
                        .foregroundColor(.pink)
                    Text("Wellness volume")
                    Spacer()
                    Text("\(Int(preferences.wellnessReminderVolume * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 40)
                }

                Slider(value: $preferences.wellnessReminderVolume, in: 0...1)

                Button("Preview Wellness Sound") {
                    SoundManager.shared.playNudge()
                }
                .buttonStyle(.bordered)
            } header: {
                Text("Wellness Reminder Sounds")
            }

            // MARK: - Alerts & Nudges Section
            Section {
                Toggle(isOn: $preferences.breakReminderSoundEnabled) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Break reminder sound")
                            Text("Play when countdown starts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.smartPauseSoundEnabled) {
                    HStack {
                        Image(systemName: "pause.circle")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Smart pause sound")
                            Text("Play when timer pauses/resumes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.activeAfterIdleSoundEnabled) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Active after idle sound")
                            Text("Alert when returning from idle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.overtimeNudgeSoundEnabled) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Overtime nudge sound")
                            Text("Play for overtime reminders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Alerts & Nudges")
            } footer: {
                Text("These sounds help you stay aware of timer states and reminders.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SightSoundEffectsView()
        .frame(width: 500, height: 700)
}
