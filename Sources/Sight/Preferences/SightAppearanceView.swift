import AppKit
import SwiftUI

// MARK: - Appearance Settings View

struct SightAppearanceView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var showMessageEditor = false
    @State private var newMessage = ""
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            ScrollView {
                VStack(alignment: .leading, spacing: SightTheme.sectionSpacing) {
                    // App Appearance section
                    appAppearanceSection

                    // Break Screen section
                    breakScreenSection

                    // Custom Messages section
                    customMessagesSection

                    // Alerts Positioning section
                    alertsPositioningSection
                }
                .padding(SightTheme.sectionSpacing)
            }
        }
        .background(SightTheme.background)
        .sheet(isPresented: $showMessageEditor) {
            messageEditorSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance")
                    .font(SightTheme.titleFont)
                    .foregroundColor(.white)

                Text("Customize how your break screen looks")
                    .font(.system(size: 13))
                    .foregroundColor(SightTheme.secondaryText)
            }

            Spacer()

            // Preview button
            Button(action: {
                // Show a preview break for 5 seconds
                Renderer.showBreak(durationSeconds: 5)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                    Text("Preview")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SightTheme.accent.opacity(0.3))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, SightTheme.sectionSpacing)
        .padding(.top, SightTheme.sectionSpacing)
        .padding(.bottom, 16)
    }

    // MARK: - App Appearance Section

    private var appAppearanceSection: some View {
        EnhancedSettingsCard(
            icon: "moon.stars",
            iconColor: .indigo,
            title: "App Appearance",
            delay: 0
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Scheme")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                HStack(spacing: 12) {
                    AppearanceModeCard(
                        mode: "system",
                        title: "System",
                        icon: "laptopcomputer",
                        isSelected: preferences.appearanceMode == "system"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.appearanceMode = "system"
                        }
                    }

                    AppearanceModeCard(
                        mode: "light",
                        title: "Light",
                        icon: "sun.max.fill",
                        isSelected: preferences.appearanceMode == "light"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.appearanceMode = "light"
                        }
                    }

                    AppearanceModeCard(
                        mode: "dark",
                        title: "Dark",
                        icon: "moon.fill",
                        isSelected: preferences.appearanceMode == "dark"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.appearanceMode = "dark"
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                Divider()
                    .background(SightTheme.divider)
                    .padding(.horizontal, 16)

                // Accent Color section
                Text("Accent Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Preset colors
                HStack(spacing: 10) {
                    ForEach(accentColorPresets, id: \.name) { preset in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                preferences.accentHue = preset.hue
                            }
                        }) {
                            Circle()
                                .fill(Color(hue: preset.hue, saturation: 0.7, brightness: 0.8))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            Color.white,
                                            lineWidth: isAccentSelected(preset.hue) ? 2 : 0)
                                )
                                .scaleEffect(isAccentSelected(preset.hue) ? 1.1 : 1.0)
                                .shadow(
                                    color: Color(hue: preset.hue, saturation: 0.7, brightness: 0.8)
                                        .opacity(0.4), radius: isAccentSelected(preset.hue) ? 6 : 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                // Hue slider for custom color
                HStack(spacing: 12) {
                    Text("Custom")
                        .font(.system(size: 11))
                        .foregroundColor(SightTheme.secondaryText)

                    // Rainbow gradient slider
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: (0..<12).map {
                                            Color(
                                                hue: Double($0) / 12.0, saturation: 0.7,
                                                brightness: 0.8)
                                        }),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 8)

                        GeometryReader { geo in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                                .shadow(radius: 2)
                                .offset(x: CGFloat(preferences.accentHue) * (geo.size.width - 16))
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let newHue = min(
                                                max(value.location.x / geo.size.width, 0), 1)
                                            preferences.accentHue = Double(newHue)
                                        }
                                )
                        }
                        .frame(height: 16)
                    }
                    .frame(height: 16)

                    // Preview swatch
                    Circle()
                        .fill(Color(hue: preferences.accentHue, saturation: 0.7, brightness: 0.8))
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Accent Color Helpers

    private var accentColorPresets: [(name: String, hue: Double)] {
        [
            ("Cyan", 0.52),
            ("Green", 0.35),
            ("Blue", 0.60),
            ("Purple", 0.75),
            ("Pink", 0.92),
            ("Orange", 0.08),
            ("Yellow", 0.15),
        ]
    }

    private func isAccentSelected(_ hue: Double) -> Bool {
        abs(preferences.accentHue - hue) < 0.05
    }

    // MARK: - Break Screen Section

    private var breakScreenSection: some View {
        EnhancedSettingsCard(
            icon: "paintpalette",
            iconColor: .pink,
            title: "Break Screen",
            delay: 0
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Background option label
                HStack {
                    Text("Background")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Background type cards
                HStack(spacing: 12) {
                    BackgroundTypeCard(
                        type: "custom",
                        title: "Custom Image",
                        icon: "photo.badge.plus",
                        isSelected: preferences.breakBackgroundType == "custom",
                        customImagePath: preferences.breakCustomImagePath,
                        isDropTargeted: $isDropTargeted
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakBackgroundType = "custom"
                        }
                    } onDrop: { path in
                        preferences.breakCustomImagePath = path
                        preferences.breakBackgroundType = "custom"
                    }

                    BackgroundTypeCard(
                        type: "wallpaper",
                        title: "Wallpaper",
                        icon: "desktopcomputer",
                        isSelected: preferences.breakBackgroundType == "wallpaper",
                        customImagePath: nil,
                        isDropTargeted: .constant(false)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakBackgroundType = "wallpaper"
                        }
                    } onDrop: { _ in
                    }

                    BackgroundTypeCard(
                        type: "gradient",
                        title: "Gradient",
                        icon: "circle.lefthalf.filled",
                        isSelected: preferences.breakBackgroundType == "gradient",
                        customImagePath: nil,
                        isDropTargeted: .constant(false)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakBackgroundType = "gradient"
                        }
                    } onDrop: { _ in
                    }
                }
                .padding(.horizontal, 16)

                // Gradient preset picker (shows when gradient is selected)
                if preferences.breakBackgroundType == "gradient" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gradient Style")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SightTheme.secondaryText)

                        HStack(spacing: 8) {
                            ForEach(SightTheme.GradientPreset.allCases, id: \.rawValue) { preset in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        preferences.breakGradientPreset = preset.rawValue
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(preset.gradient)
                                            .frame(width: 50, height: 30)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(
                                                        preferences.breakGradientPreset
                                                            == preset.rawValue
                                                            ? Color.white : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )

                                        Text(preset.displayName)
                                            .font(.system(size: 10))
                                            .foregroundColor(
                                                preferences.breakGradientPreset == preset.rawValue
                                                    ? .white : SightTheme.tertiaryText
                                            )
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                Divider()
                    .background(SightTheme.divider)
                    .padding(.horizontal, 16)

                // Blur background toggle
                EnhancedToggleRow(
                    title: "Blur background",
                    description: "Apply a blur effect to the break screen background",
                    icon: "drop.fill",
                    isOn: $preferences.breakBlurBackground
                )

                // Clear image button (only show when custom image is set)
                if preferences.breakBackgroundType == "custom"
                    && !preferences.breakCustomImagePath.isEmpty
                {
                    Divider()
                        .background(SightTheme.divider)
                        .padding(.horizontal, 16)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom image")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)

                            Text(
                                URL(fileURLWithPath: preferences.breakCustomImagePath)
                                    .lastPathComponent
                            )
                            .font(.system(size: 11))
                            .foregroundColor(SightTheme.tertiaryText)
                            .lineLimit(1)
                        }

                        Spacer()

                        Button(action: {
                            preferences.breakCustomImagePath = ""
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("Clear")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Custom Messages Section

    private var customMessagesSection: some View {
        EnhancedSettingsCard(
            icon: "text.bubble",
            iconColor: .cyan,
            title: "Messages",
            delay: 0.05
        ) {
            VStack(spacing: 0) {
                // Custom messages row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom messages")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text(
                            "\(preferences.breakCustomMessages.count) message\(preferences.breakCustomMessages.count == 1 ? "" : "s") added"
                        )
                        .font(.system(size: 11))
                        .foregroundColor(SightTheme.tertiaryText)
                    }

                    Spacer()

                    Button(action: { showMessageEditor = true }) {
                        Text("Customize...")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                Divider()
                    .background(SightTheme.divider)
                    .padding(.horizontal, 16)

                // Hide messages toggle
                EnhancedToggleRow(
                    title: "Hide all break screen messages",
                    description: "Show only timer and breathing guide",
                    icon: "eye.slash",
                    isOn: $preferences.breakHideMessages
                )
            }
        }
    }

    // MARK: - Alerts Positioning Section

    private var alertsPositioningSection: some View {
        EnhancedSettingsCard(
            icon: "arrow.up.left.and.arrow.down.right",
            iconColor: .orange,
            title: "Alerts Positioning",
            delay: 0.1
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Top positions
                HStack(spacing: 12) {
                    AlertPositionCard(
                        position: "topLeft",
                        title: "Top left",
                        isSelected: preferences.breakAlertPosition == "topLeft"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakAlertPosition = "topLeft"
                        }
                    }

                    AlertPositionCard(
                        position: "topCenter",
                        title: "Top center",
                        isSelected: preferences.breakAlertPosition == "topCenter"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakAlertPosition = "topCenter"
                        }
                    }

                    AlertPositionCard(
                        position: "topRight",
                        title: "Top right",
                        isSelected: preferences.breakAlertPosition == "topRight"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakAlertPosition = "topRight"
                        }
                    }
                }

                // Bottom positions
                HStack(spacing: 12) {
                    AlertPositionCard(
                        position: "bottomLeft",
                        title: "Bottom left",
                        isSelected: preferences.breakAlertPosition == "bottomLeft"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakAlertPosition = "bottomLeft"
                        }
                    }

                    AlertPositionCard(
                        position: "bottomCenter",
                        title: "Bottom center",
                        isSelected: preferences.breakAlertPosition == "bottomCenter"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakAlertPosition = "bottomCenter"
                        }
                    }

                    AlertPositionCard(
                        position: "bottomRight",
                        title: "Bottom right",
                        isSelected: preferences.breakAlertPosition == "bottomRight"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preferences.breakAlertPosition = "bottomRight"
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Message Editor Sheet

    private var messageEditorSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Custom Messages")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showMessageEditor = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(SightTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().background(SightTheme.divider)

            // Message list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(preferences.breakCustomMessages, id: \.self) { message in
                        HStack {
                            Text(message)
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                if let index = preferences.breakCustomMessages.firstIndex(
                                    of: message)
                                {
                                    preferences.breakCustomMessages.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }

                    if preferences.breakCustomMessages.isEmpty {
                        Text("No custom messages yet")
                            .font(.system(size: 14))
                            .foregroundColor(SightTheme.tertiaryText)
                            .padding(.vertical, 30)
                    }
                }
                .padding(20)
            }

            Divider().background(SightTheme.divider)

            // Add new message
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Enter a message...", text: $newMessage)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .onChange(of: newMessage) { newValue in
                            // Limit to 100 characters
                            if newValue.count > 100 {
                                newMessage = String(newValue.prefix(100))
                            }
                        }

                    // Character count
                    Text("\(newMessage.count)/100")
                        .font(.system(size: 10))
                        .foregroundColor(newMessage.count >= 90 ? .orange : SightTheme.tertiaryText)
                }

                Button(action: {
                    let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        preferences.breakCustomMessages.append(trimmed)
                        newMessage = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SightTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .frame(width: 400, height: 450)
        .background(SightTheme.background)
    }
}

// MARK: - Background Type Card

struct BackgroundTypeCard: View {
    let type: String
    let title: String
    let icon: String
    let isSelected: Bool
    let customImagePath: String?
    @Binding var isDropTargeted: Bool
    let action: () -> Void
    let onDrop: (String) -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Preview area
                ZStack {
                    if type == "custom" {
                        // Custom image or drop zone
                        if let path = customImagePath, !path.isEmpty {
                            // Check if file exists
                            if FileManager.default.fileExists(atPath: path),
                                let image = NSImage(contentsOfFile: path)
                            {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 110, height: 70)
                                    .clipped()
                                    .cornerRadius(10)
                            } else {
                                // File missing - show error state
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 110, height: 70)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.red.opacity(0.5), lineWidth: 2)
                                    )
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 16))
                                            Text("File Missing")
                                                .font(.system(size: 9))
                                        }
                                        .foregroundColor(Color.red.opacity(0.8))
                                    )
                            }
                        } else {
                            // Drop zone
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(
                                    isDropTargeted ? SightTheme.accent : Color.white.opacity(0.2)
                                )
                                .frame(width: 110, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.03))
                                )
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: icon)
                                            .font(.system(size: 16))
                                        Text("Drag & Drop")
                                            .font(.system(size: 9))
                                    }
                                    .foregroundColor(Color.white.opacity(0.4))
                                )
                        }
                    } else if type == "wallpaper" {
                        // Blurred wallpaper preview
                        if let wallpaperImage = getWallpaperPreview() {
                            Image(nsImage: wallpaperImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 70)
                                .blur(radius: 3)
                                .clipped()
                                .cornerRadius(10)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.3), Color.purple.opacity(0.3),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 70)
                                .blur(radius: 3)
                        }
                    } else {
                        // Gradient preview - use user's selected preset
                        let preset =
                            SightTheme.GradientPreset(
                                rawValue: PreferencesManager.shared.breakGradientPreset
                            ) ?? .sunset
                        RoundedRectangle(cornerRadius: 10)
                            .fill(preset.gradient)
                            .frame(width: 110, height: 70)

                        // Checkmark for gradient
                        if isSelected {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(SightTheme.accent)
                                )
                                .offset(x: 35, y: -20)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : SightTheme.secondaryText)
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SightTheme.accent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) background")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            guard type == "custom" else { return false }
            return handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            if let error = error {
                print("[SightAppearanceView] Drop failed: \(error.localizedDescription)")
                return
            }

            guard let data = item as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil),
                isImageFile(url: url)
            else {
                print("[SightAppearanceView] Invalid drop: not an image file")
                return
            }

            DispatchQueue.main.async {
                onDrop(url.path)
            }
        }

        return true
    }

    private func isImageFile(url: URL) -> Bool {
        let imageExtensions = [
            "jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "tiff", "tif", "bmp",
        ]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }

    private func getWallpaperPreview() -> NSImage? {
        // Try to get current desktop wallpaper
        if let screen = NSScreen.main,
            let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen),
            let image = NSImage(contentsOf: wallpaperURL)
        {
            return image
        }
        return nil
    }
}

// MARK: - Alert Position Card

struct AlertPositionCard: View {
    let position: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    // Mock landscape background
    private let landscapeGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.75, blue: 0.9),
            Color(red: 0.85, green: 0.8, blue: 0.7),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Preview with landscape and alert indicator
                ZStack {
                    // Background landscape
                    RoundedRectangle(cornerRadius: 10)
                        .fill(landscapeGradient)
                        .frame(width: 140, height: 85)

                    // Alert indicator (pill shape)
                    VStack {
                        if position.contains("top") {
                            HStack {
                                if position == "topLeft" {
                                    alertPill
                                    Spacer()
                                } else if position == "topCenter" {
                                    Spacer()
                                    alertPill
                                    Spacer()
                                } else {
                                    Spacer()
                                    alertPill
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                            Spacer()
                        } else if position.contains("bottom") {
                            Spacer()
                            HStack {
                                if position == "bottomLeft" {
                                    alertPill
                                    Spacer()
                                } else if position == "bottomCenter" {
                                    Spacer()
                                    alertPill
                                    Spacer()
                                } else {
                                    Spacer()
                                    alertPill
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                    }
                    .frame(width: 140, height: 85)
                }

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : SightTheme.secondaryText)
            }
            .padding(8)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? SightTheme.accent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) alert position")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
    }

    private var alertPill: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.6))
                .frame(width: 30, height: 6)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 8, height: 6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.9))
        )
    }
}

// MARK: - Appearance Mode Card

struct AppearanceModeCard: View {
    let mode: String
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : SightTheme.secondaryText)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : SightTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(isSelected ? 0.1 : 0.03))
            .overlay(
                RoundedRectangle(cornerRadius: SightTheme.smallCornerRadius)
                    .stroke(isSelected ? SightTheme.accent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(SightTheme.smallCornerRadius)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) appearance mode")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
    }
}

#Preview {
    SightAppearanceView()
        .frame(width: 700, height: 600)
}
