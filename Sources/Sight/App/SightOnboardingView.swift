import SwiftUI
import UserNotifications

// MARK: - Enhanced Onboarding View

public struct SightOnboardingView: View {
    @State private var currentStep = 0
    @State private var selectedProfile: BreakProfile = .deepWork
    @State private var workInterval = 20
    @State private var breakDuration = 20

    private let totalSteps = 5

    /// Format break duration for display (shows minutes for >= 60 sec, otherwise seconds)
    private var breakDurationFormatted: String {
        if breakDuration >= 60 {
            let minutes = breakDuration / 60
            let seconds = breakDuration % 60
            if seconds == 0 {
                return "\(minutes) min"
            } else {
                return "\(minutes)m \(seconds)s"
            }
        } else {
            return "\(breakDuration) sec"
        }
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))

                    Rectangle()
                        .fill(Color.cyan)
                        .frame(
                            width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps))
                }
            }
            .frame(height: 3)

            // Content
            ZStack {
                switch currentStep {
                case 0: welcomeStep
                case 1: rulesStep
                case 2: profileStep
                case 3: intervalsStep
                case 4: permissionsStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button("Continue") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
            }
            .padding(24)
        }
        .frame(width: 550, height: 450)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "eye.fill")
                .font(.system(size: 60))
                .foregroundColor(.cyan)

            Text("Welcome to Sight")
                .font(.system(size: 28, weight: .bold))

            Text("Your personal eye care assistant.\nTake smart breaks and protect your vision.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Step 2: Rules

    private var rulesStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("The 20-20-20 Rule")
                .font(.system(size: 24, weight: .bold))

            HStack(spacing: 20) {
                RuleCircle(number: "20", label: "minutes", subtitle: "of work")

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                RuleCircle(number: "20", label: "seconds", subtitle: "break")

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                RuleCircle(number: "20", label: "feet", subtitle: "away")
            }

            Text("Sight automates this habit,\nkeeping your eyes healthy without breaking flow.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Step 3: Profile Selection

    private var profileStep: some View {
        VStack(spacing: 24) {
            Text("Choose Your Style")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 30)

            Text("Select a profile that matches your work style")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach(BreakProfile.allCases.filter { $0 != .custom }, id: \.self) { profile in
                    ProfileCard(
                        profile: profile,
                        isSelected: selectedProfile == profile,
                        onSelect: {
                            selectedProfile = profile
                            // Sync sliders with profile defaults
                            workInterval = profile.workInterval / 60  // Convert seconds to minutes
                            breakDuration = profile.breakDuration  // Keep in seconds
                        }
                    )
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Step 4: Intervals

    private var intervalsStep: some View {
        VStack(spacing: 24) {
            Text("Fine-tune Your Settings")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 30)

            VStack(spacing: 20) {
                // Work interval
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Work Interval")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text("\(workInterval) min")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(workInterval) },
                            set: { workInterval = Int($0) }
                        ), in: 10...60, step: 5
                    )
                    .accentColor(.cyan)
                }

                // Break duration
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Break Duration")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text(breakDurationFormatted)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(breakDuration) },
                            set: { breakDuration = Int($0) }
                        ), in: 20...300, step: 10
                    )
                    .accentColor(.green)
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 20)

            Text("You can always change these in Settings")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - Step 5: Permissions

    private var permissionsStep: some View {
        VStack(spacing: 24) {
            Text("Almost Ready!")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 30)

            VStack(spacing: 16) {
                PermissionRow(
                    icon: "bell.badge.fill",
                    iconColor: .red,
                    title: "Notifications",
                    subtitle: "Get notified when it's break time"
                ) {
                    requestNotifications()
                }

                PermissionRow(
                    icon: "calendar",
                    iconColor: .orange,
                    title: "Calendar (Optional)",
                    subtitle: "Only checks if a meeting is now – event details stay private"
                ) {
                    Task {
                        await MeetingDetector.shared.requestAccess()
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Text("Sight runs quietly in your menu bar")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
        }
    }

    private func completeOnboarding() {
        // Save settings - set profile first, then apply custom intervals
        // (applyProfile would overwrite intervals, so we set them after)
        PreferencesManager.shared.activeProfile = selectedProfile
        PreferencesManager.shared.workIntervalSeconds = workInterval * 60
        PreferencesManager.shared.breakDurationSeconds = breakDuration
        PreferencesManager.shared.hasCompletedOnboarding = true

        // Close window
        if let window = NSApp.windows.first(where: {
            $0.title.contains("Welcome") || $0.contentView?.frame.size.width == 550
        }) {
            window.close()
        }
    }
}

// MARK: - Components

private struct RuleCircle: View {
    let number: String
    let label: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 70, height: 70)

                VStack(spacing: 0) {
                    Text(number)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

private struct ProfileCard: View {
    let profile: BreakProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: profile.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .cyan)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.cyan : Color.cyan.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(profile.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cyan)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.1) : Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var requested = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(requested ? "Requested" : "Allow") {
                action()
                requested = true
            }
            .buttonStyle(.bordered)
            .disabled(requested)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
