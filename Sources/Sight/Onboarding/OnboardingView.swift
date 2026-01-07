import SwiftUI

// MARK: - Onboarding View (macOS System Style)

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case breakRoutine
    case wellnessReminders
    case permissions
    case completion

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .breakRoutine: return "Break Routine"
        case .wellnessReminders: return "Wellness"
        case .permissions: return "Permissions"
        case .completion: return "You're All Set"
        }
    }

    // System Settings style icons
    var iconName: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .breakRoutine: return "clock.fill"
        case .wellnessReminders: return "heart.text.square.fill"
        case .permissions: return "lock.shield.fill"
        case .completion: return "checkmark.circle.fill"
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .welcome:
            return LinearGradient(
                colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .breakRoutine:
            return LinearGradient(
                colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .wellnessReminders:
            return LinearGradient(
                colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .permissions:
            return LinearGradient(
                colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .completion:
            return LinearGradient(
                colors: [.green, .teal], startPoint: .topLeading,
                endPoint: .bottomTrailing)
        }
    }
}

public struct OnboardingView: View {
    @State private var currentStep: OnboardingStep? = .welcome

    // Settings State
    @State private var workDuration: Int = 20
    @State private var breakDuration: Int = 20
    @State private var postureEnabled: Bool = true
    @State private var postureInterval: Int = 20
    @State private var blinkEnabled: Bool = true
    @State private var blinkInterval: Int = 20

    public init() {}

    // Custom Visual Effect View for sidebar
    struct OnboardingVisualEffectView: NSViewRepresentable {
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

    public var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            List(selection: $currentStep) {
                Section {
                    ForEach(OnboardingStep.allCases) { step in
                        NavigationLink(value: step) {
                            HStack(spacing: 10) {
                                SettingsIcon(
                                    iconName: step.iconName,
                                    gradient: step.iconGradient,
                                    size: 24
                                )

                                Text(step.title)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                // Completion checkmark for visited steps
                                if step.rawValue < (currentStep?.rawValue ?? 0) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Sight Setup")
                    }
                    .font(.subheadline.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                    .padding(.top, 20)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            .listStyle(.sidebar)
            .safeAreaInset(edge: .top) {
                Spacer().frame(height: 44)  // Clear traffic lights (Standard Height)
            }
            .background(OnboardingVisualEffectView(material: .sidebar, blendingMode: .behindWindow))

        } detail: {
            // MARK: - Content
            VStack(spacing: 0) {
                if let step = currentStep {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {

                            // Header (Only for Form steps)
                            if step != .welcome && step != .completion && step != .permissions {
                                HStack(spacing: 16) {
                                    SettingsIcon(
                                        iconName: step.iconName, gradient: step.iconGradient,
                                        size: 48)
                                    Text(step.title)
                                        .font(.system(size: 32, weight: .bold))  // Large Title Bold
                                }
                                .padding(.top, 40)  // Increased top spacing
                                .padding(.horizontal, 40)
                            }

                            // Step Content
                            Group {
                                switch step {
                                case .welcome:
                                    WelcomeContent(nextAction: goToNextStep)
                                        .padding(.horizontal, 30)
                                case .breakRoutine:
                                    BreakRoutineContent(
                                        workDuration: $workDuration,
                                        breakDuration: $breakDuration
                                    )
                                    .frame(maxWidth: 500)
                                    .padding(.horizontal, 20)
                                case .wellnessReminders:
                                    WellnessContent(
                                        postureEnabled: $postureEnabled,
                                        postureInterval: $postureInterval,
                                        blinkEnabled: $blinkEnabled,
                                        blinkInterval: $blinkInterval
                                    )
                                    .frame(maxWidth: 500)
                                    .padding(.horizontal, 20)
                                case .permissions:
                                    PermissionsContent()
                                        .frame(maxWidth: 500)
                                        .padding(.horizontal, 20)
                                case .completion:
                                    CompletionContent(
                                        workDuration: workDuration,
                                        breakDuration: breakDuration,
                                        completeAction: completeOnboarding
                                    )
                                    .padding(.horizontal, 30)
                                }
                            }
                            .id(step)  // Identity for transition
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing))
                                        .animation(.easeOut(duration: 0.2)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                        .animation(.easeIn(duration: 0.15))
                                ))
                        }
                        .padding(.bottom, 60)
                    }
                } else {
                    Text("Select a step")
                        .foregroundColor(.secondary)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .safeAreaInset(edge: .bottom) {
                // Bottom Navigation Bar
                // Bottom Navigation Bar
                if let step = currentStep, step != .welcome, step != .completion {
                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            Button("Back") {
                                goToPreviousStep()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .keyboardShortcut(.cancelAction)

                            Spacer()

                            Button("Continue") {
                                goToNextStep()
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                        }
                        .padding(20)
                        .background(Color(nsColor: .windowBackgroundColor))
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: - Logic

    private func goToNextStep() {
        guard let current = currentStep, let next = OnboardingStep(rawValue: current.rawValue + 1)
        else { return }
        withAnimation {
            currentStep = next
        }
    }

    private func goToPreviousStep() {
        guard let current = currentStep, let prev = OnboardingStep(rawValue: current.rawValue - 1)
        else { return }
        withAnimation {
            currentStep = prev
        }
    }

    private func completeOnboarding() {
        PreferencesManager.shared.workIntervalSeconds = workDuration * 60
        PreferencesManager.shared.breakDurationSeconds = breakDuration
        PreferencesManager.shared.postureReminderEnabled = postureEnabled
        PreferencesManager.shared.postureReminderIntervalSeconds = postureInterval * 60
        PreferencesManager.shared.blinkReminderEnabled = blinkEnabled
        PreferencesManager.shared.blinkReminderIntervalSeconds = blinkInterval * 60

        PreferencesManager.shared.hasCompletedOnboarding = true
        NotificationCenter.default.post(
            name: NSNotification.Name("OnboardingCompleted"), object: nil)

        for window in NSApplication.shared.windows {
            if window.identifier?.rawValue == "onboarding" {
                window.close()
                return
            }
        }
    }
}

// MARK: - Components

struct SettingsIcon: View {
    let iconName: String
    let gradient: LinearGradient
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(gradient)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)

            Image(systemName: iconName)
                .font(.system(size: size * 0.55, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Content Views

struct WelcomeContent: View {
    let nextAction: () -> Void

    @State private var animateHero = false
    @State private var animateTitle = false
    @State private var animateRows = false
    @State private var animateButton = false
    @State private var pulseGlow = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Hero Icon with pulsing glow
            ZStack {
                // Glow layer
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseGlow ? 1.1 : 0.9)
                    .opacity(pulseGlow ? 0.6 : 0.3)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseGlow)

                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple], startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .opacity(animateHero ? 1 : 0)
            .scaleEffect(animateHero ? 1 : 0.8)
            .onAppear {
                withAnimation(.spring(duration: 0.6)) { animateHero = true }
                pulseGlow = true
            }

            VStack(spacing: 8) {
                Text("Welcome to Sight")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Your personal vision health companion.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .opacity(animateTitle ? 1 : 0)
            .offset(y: animateTitle ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { animateTitle = true }
            }

            VStack(alignment: .leading, spacing: 16) {
                OnboardingFeatureRow(
                    icon: "timer", color: .blue, title: "Smart Breaks",
                    description: "The 20-20-20 rule with customizable intervals"
                )
                .opacity(animateRows ? 1 : 0)
                .offset(x: animateRows ? 0 : -20)

                OnboardingFeatureRow(
                    icon: "eye", color: .cyan, title: "Eye Care",
                    description: "Gentle blink reminders to prevent dry eyes"
                )
                .opacity(animateRows ? 1 : 0)
                .offset(x: animateRows ? 0 : -20)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: animateRows)

                OnboardingFeatureRow(
                    icon: "figure.stand", color: .green, title: "Posture Check",
                    description: "Reminders to sit up straight and stretch"
                )
                .opacity(animateRows ? 1 : 0)
                .offset(x: animateRows ? 0 : -20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: animateRows)

                OnboardingFeatureRow(
                    icon: "lock.shield", color: .purple, title: "100% Private",
                    description: "No accounts, no data collection — just your Mac"
                )
                .opacity(animateRows ? 1 : 0)
                .offset(x: animateRows ? 0 : -20)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: animateRows)
            }
            .padding(.vertical, 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.4)) { animateRows = true }
            }

            Spacer()

            Button("Get Started") {
                nextAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 300)
            .padding(.bottom, 20)
            .opacity(animateButton ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.9)) { animateButton = true }
            }
        }
        .frame(maxWidth: 600)
        .padding(.horizontal, 40)
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        .cornerRadius(10)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

struct BreakRoutineContent: View {
    @Binding var workDuration: Int
    @Binding var breakDuration: Int

    var body: some View {
        Form {
            Section {
                Picker(selection: $workDuration) {
                    Text("15 minutes").tag(15)
                    HStack {
                        Text("20 minutes")
                        Spacer()
                        Text("Recommended")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                    }.tag(20)
                    Text("30 minutes").tag(30)
                    Text("45 minutes").tag(45)
                    Text("60 minutes").tag(60)
                } label: {
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.orange)
                        Text("Break every")
                    }
                }
                .pickerStyle(.menu)

                Picker(selection: $breakDuration) {
                    Text("15 seconds").tag(15)
                    HStack {
                        Text("20 seconds")
                        Spacer()
                        Text("Recommended")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                    }.tag(20)
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                } label: {
                    HStack {
                        Image(systemName: "stopwatch")
                            .foregroundColor(.blue)
                        Text("Break duration")
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("20-20-20 Rule")
            } footer: {
                Label(
                    "Every 20 minutes, look at something 20 feet away for 20 seconds.",
                    systemImage: "lightbulb"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct WellnessContent: View {
    @Binding var postureEnabled: Bool
    @Binding var postureInterval: Int
    @Binding var blinkEnabled: Bool
    @Binding var blinkInterval: Int

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $postureEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.stand")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Posture Check")
                            Text("Gentle reminders to sit up straight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)

                if postureEnabled {
                    Picker("Reminder every", selection: $postureInterval) {
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                        Text("30 minutes").tag(30)
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Physical Wellness")
            }

            Section {
                Toggle(isOn: $blinkEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Blink Reminder")
                            Text("Helps prevent dry eyes from screen use")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)

                if blinkEnabled {
                    Picker("Reminder every", selection: $blinkInterval) {
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                        Text("30 minutes").tag(30)
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Eye Health")
            } footer: {
                Label(
                    "Studies show we blink 66% less when looking at screens.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct PermissionsContent: View {
    @StateObject private var permissionManager = OnboardingPermissionManager.shared
    @State private var launchAtLogin: Bool = LoginItemManager.shared.isEnabled

    var body: some View {
        Form {
            // Required Permissions
            Section {
                PermissionRow(
                    icon: "bell.badge.fill",
                    iconColor: .red,
                    title: "Notifications",
                    description: "Get notified when breaks are due",
                    status: permissionManager.notificationStatus,
                    action: {
                        Task { await permissionManager.requestNotifications() }
                    },
                    openSettings: { permissionManager.openSettings(for: .notifications) }
                )
            } header: {
                Text("Required")
            } footer: {
                Text("Notifications are essential for break reminders.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Startup
            Section {
                Toggle(isOn: $launchAtLogin) {
                    HStack(spacing: 10) {
                        Image(systemName: "power")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Launch at Login")
                            Text("Start Sight when you log in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { newValue in
                    LoginItemManager.shared.setEnabled(newValue)
                }
            } header: {
                Text("Startup")
            }

            // Optional Permissions
            Section {
                PermissionRow(
                    icon: "calendar",
                    iconColor: .orange,
                    title: "Calendar",
                    description: "Pause breaks during meetings",
                    status: permissionManager.calendarStatus,
                    action: {
                        Task { await permissionManager.requestCalendar() }
                    },
                    openSettings: { permissionManager.openSettings(for: .calendar) }
                )

                PermissionRow(
                    icon: "accessibility",
                    iconColor: .blue,
                    title: "Accessibility",
                    description: "Enable global keyboard shortcuts",
                    status: permissionManager.accessibilityStatus,
                    action: {
                        _ = permissionManager.requestAccessibility()
                    },
                    openSettings: { permissionManager.openAccessibilitySettings() }
                )
            } header: {
                Text("Optional")
            } footer: {
                Text("These permissions enhance the experience but are not required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            Task { await permissionManager.refreshAllStatuses() }
        }
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let status: PermissionState
    let action: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if status.isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
            } else {
                Button(status == .denied ? "Open Settings" : "Allow") {
                    if status == .denied {
                        openSettings()
                    } else {
                        action()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CompletionContent: View {
    let workDuration: Int
    let breakDuration: Int
    let completeAction: () -> Void

    @State private var showCheck = false
    @State private var showText = false
    @State private var showInfo = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Success Icon
            ZStack {
                if showCheck {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint], startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                        .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 90)

            VStack(spacing: 8) {
                Text("Sight is Ready")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Your first break will be in \(workDuration) minutes.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    showCheck = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                    showText = true
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "menubar.dock.rectangle")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Menu Bar Controls")
                            .font(.headline)
                        Text("Look for the eye icon to pause, skip, or change settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    Image(systemName: "command")
                        .font(.system(size: 28))
                        .foregroundColor(.purple)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keyboard Shortcuts")
                            .font(.headline)
                        Text("⌘⇧B to take a break • ⌘⇧S to pause")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 400)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .opacity(showInfo ? 1 : 0)
            .offset(y: showInfo ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                    showInfo = true
                }
            }

            Spacer()

            Button("Finish Setup") {
                completeAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 300)
            .padding(.bottom, 20)
            .opacity(showButton ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                    showButton = true
                }
            }
        }
        .frame(maxWidth: 600)
        .padding(.horizontal, 40)
    }
}
