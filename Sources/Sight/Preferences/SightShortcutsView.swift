import SwiftUI

// MARK: - Shortcuts View

struct SightShortcutsView: View {
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var permissionCheckTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    if !shortcutManager.hasAccessibilityAccess {
                        permissionBanner
                    }

                    shortcutsSection

                    tipsSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(SightTheme.background)
        .onAppear {
            shortcutManager.checkPermissions()
            // Invalidate any existing timer before creating new one
            permissionCheckTimer?.invalidate()
            // Start polling for permission changes
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                shortcutManager.checkPermissions()
            }
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Control Sight from anywhere on your Mac")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(shortcutManager.hasAccessibilityAccess ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(shortcutManager.hasAccessibilityAccess ? "Active" : "Inactive")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(shortcutManager.hasAccessibilityAccess ? .green : .orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        (shortcutManager.hasAccessibilityAccess ? Color.green : Color.orange)
                            .opacity(0.15))
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Accessibility Access Required")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Shortcuts need permission to work globally")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Grant Access") {
                shortcutManager.requestPermissions()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Shortcuts Section

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SHORTCUTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()

                Toggle("", isOn: $preferences.shortcutsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }

            VStack(spacing: 0) {
                EditableShortcutRow(
                    icon: "pause.fill",
                    title: "Pause / Resume",
                    shortcut: $preferences.shortcutToggleTimer
                )
                Divider().padding(.leading, 50)
                EditableShortcutRow(
                    icon: "cup.and.saucer.fill",
                    title: "Take Break Now",
                    shortcut: $preferences.shortcutTakeBreak
                )
                Divider().padding(.leading, 50)
                EditableShortcutRow(
                    icon: "forward.fill",
                    title: "Skip Break",
                    shortcut: $preferences.shortcutSkipBreak
                )
                Divider().padding(.leading, 50)
                EditableShortcutRow(
                    icon: "gearshape.fill",
                    title: "Preferences",
                    shortcut: $preferences.shortcutPreferences
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Reset button
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    preferences.shortcutToggleTimer = "cmd+ctrl:35"
                    preferences.shortcutTakeBreak = "cmd+ctrl:11"
                    preferences.shortcutSkipBreak = "cmd+ctrl:1"
                    preferences.shortcutPreferences = "cmd+ctrl:43"
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
        }
        .opacity(shortcutManager.hasAccessibilityAccess ? 1 : 0.5)
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TIPS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 8) {
                TipText(text: "Shortcuts work even when Sight is in the background")
                TipText(text: "Press Escape during a break to dismiss")
                TipText(text: "Use ⌘⌃P to pause during important work")
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial.opacity(0.5))
            )
        }
    }
}

// MARK: - Editable Shortcut Row

private struct EditableShortcutRow: View {
    let icon: String
    let title: String
    @Binding var shortcut: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer()

            // Display current shortcut
            Text(ShortcutManager.displayString(for: shortcut))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let icon: String
    let title: String
    let keys: [String]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                        .frame(minWidth: 24, minHeight: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Tip Text

private struct TipText: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
}

#Preview {
    SightShortcutsView()
        .frame(width: 600, height: 500)
}
