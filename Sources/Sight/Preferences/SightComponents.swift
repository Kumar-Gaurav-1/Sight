import SwiftUI

// MARK: - Settings Card

/// A card container for settings sections
struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(SightTheme.cardBackground)
        .cornerRadius(SightTheme.cardCornerRadius)
    }
}

// MARK: - Settings Toggle Row

/// A toggle row with title, description, and switch
struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(SightTheme.secondaryText)
                    .lineLimit(3)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(SightTheme.accent)
        }
        .padding(SightTheme.cardPadding)
    }
}

// MARK: - Settings Dropdown Row

/// A dropdown/picker row with title and description
struct SettingsDropdownRow<T: Hashable>: View {
    let title: String
    let description: String
    @Binding var selection: T
    let options: [(label: String, value: T)]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(SightTheme.secondaryText)
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.menu)
            .frame(minWidth: 80)
            .background(SightTheme.elevatedBackground)
            .cornerRadius(6)
        }
        .padding(SightTheme.cardPadding)
    }
}

// MARK: - Large Value Slider

/// A slider with a large value display above it
struct LargeValueSlider: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let tickMarks: [Double]
    var showEditButton: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with edit button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(SightTheme.secondaryText)
                }
                
                Spacer()
                
                if showEditButton {
                    Button(action: {}) {
                        Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(SightTheme.elevatedBackground)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Large value display
            VStack(spacing: 4) {
                Text("\(Int(value))")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(SightTheme.accent)
                
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(SightTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            
            // Slider with tick marks
            VStack(spacing: 8) {
                Slider(value: $value, in: range, step: step)
                    .tint(SightTheme.accent)
                
                // Tick mark labels
                HStack {
                    ForEach(tickMarks, id: \.self) { tick in
                        Text("\(Int(tick))")
                            .font(.system(size: 10))
                            .foregroundColor(SightTheme.tertiaryText)
                        
                        if tick != tickMarks.last {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(SightTheme.cardPadding)
    }
}

// MARK: - Tab Bar

/// A horizontal tab bar for section navigation
struct SightTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab)
                        .font(.system(size: 13, weight: selectedTab == tab ? .medium : .regular))
                        .foregroundColor(selectedTab == tab ? .white : SightTheme.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(
                    VStack {
                        Spacer()
                        if selectedTab == tab {
                            Rectangle()
                                .fill(SightTheme.accent)
                                .frame(height: 2)
                        }
                    }
                )
            }
            Spacer()
        }
        .background(SightTheme.background)
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(SightTheme.divider)
                    .frame(height: 1)
            }
        )
    }
}

// MARK: - Sidebar Navigation Item

/// A sidebar navigation item with icon
struct SidebarNavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var isSystemImage: Bool = true
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            if isSystemImage {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : SightTheme.secondaryText)
                    .frame(width: 20)
            } else {
                Text(icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
            }
            
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : (isHovered ? .white.opacity(0.9) : SightTheme.secondaryText))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Group {
                if isSelected {
                    SightTheme.accent.opacity(0.2)
                } else if isHovered {
                    SightTheme.elevatedBackground
                } else {
                    Color.clear
                }
            }
        )
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Assigned Exercise Row

/// A row showing an assigned exercise
struct AssignedExerciseRow: View {
    let number: Int
    let name: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Number badge
            Text("\(number)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SightTheme.secondaryText)
                .frame(width: 24, height: 24)
                .background(SightTheme.elevatedBackground)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(SightTheme.accent)
            }
            
            Spacer()
        }
        .padding(12)
        .background(SightTheme.elevatedBackground)
        .cornerRadius(SightTheme.smallCornerRadius)
    }
}

// MARK: - Exercise Table Row

/// A table row for the exercises list
struct ExerciseTableRow: View {
    let name: String
    let title: String
    let description: String
    let assignedToShortBreak: Bool
    let assignedToLongBreak: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Name column
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)
            
            // Title column
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .frame(width: 150, alignment: .leading)
                .lineLimit(2)
            
            // Description column
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(SightTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
            
            // Assigned to column
            VStack(alignment: .leading, spacing: 4) {
                if assignedToShortBreak {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(SightTheme.success)
                            .frame(width: 8, height: 8)
                        Text("Short Break")
                            .font(.system(size: 12))
                            .foregroundColor(SightTheme.secondaryText)
                    }
                }
                if assignedToLongBreak {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(SightTheme.warning)
                            .frame(width: 8, height: 8)
                        Text("Long Break")
                            .font(.system(size: 12))
                            .foregroundColor(SightTheme.secondaryText)
                    }
                }
            }
            .frame(width: 100, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Section Divider

/// A divider for settings sections
struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(SightTheme.divider)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

// MARK: - Primary Action Button

/// A blue primary action button
struct SightPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isHovered = false
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isHovered ? SightTheme.accent.opacity(0.85) : SightTheme.accent)
            .cornerRadius(8)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Search Bar

/// A search input field
struct SightSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(SightTheme.secondaryText)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SightTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SightTheme.border, lineWidth: 1)
        )
    }
}
