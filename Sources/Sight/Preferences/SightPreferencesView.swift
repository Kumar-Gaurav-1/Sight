import SwiftUI

// MARK: - Sight Navigation

/// Available navigation tabs for the Sight-style dashboard
enum SightTab: String, CaseIterable, Identifiable {
    case general = "General"
    case breaks = "Breaks"
    case wellnessReminders = "Wellness Reminders"
    case achievements = "Achievements"
    case statistics = "Statistics"
    case shortcuts = "Shortcuts"
    case about = "About"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .breaks: return "clock"
        case .wellnessReminders: return "heart.text.square"
        case .achievements: return "trophy"
        case .statistics: return "chart.bar"
        case .shortcuts: return "command"
        case .about: return "info.circle"
        }
    }
    
    var isMainSection: Bool {
        switch self {
        case .general, .breaks, .wellnessReminders, .achievements, .statistics, .shortcuts:
            return true
        case .about:
            return false
        }
    }
}

// MARK: - Main Preferences View

/// Sight-style preferences dashboard with animated transitions
public struct SightPreferencesView: View {
    @State private var selectedTab: SightTab = .general
    @State private var previousTab: SightTab = .general
    @State private var logoGlow: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebar
            
            // Divider with subtle gradient
            Rectangle()
                .fill(LinearGradient(colors: [SightTheme.divider.opacity(0.5), SightTheme.divider, SightTheme.divider.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 1)
            
            // Content area with transition
            contentArea
        }
        .frame(minWidth: 900, minHeight: 650)
        .background(SightTheme.background)
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo area
            logoArea
            
            // Main navigation
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(SightTab.allCases.filter { $0.isMainSection }) { tab in
                        Button(action: {
                            withAnimation(SightTheme.springSmooth) {
                                previousTab = selectedTab
                                selectedTab = tab
                            }
                        }) {
                            SidebarNavItem(
                                icon: tab.icon,
                                title: tab.rawValue,
                                isSelected: selectedTab == tab
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 4) {
                ForEach(SightTab.allCases.filter { !$0.isMainSection }) { tab in
                    Button(action: {
                        withAnimation(SightTheme.springSmooth) {
                            previousTab = selectedTab
                            selectedTab = tab
                        }
                    }) {
                        SidebarNavItem(
                            icon: tab.icon,
                            title: tab.rawValue,
                            isSelected: selectedTab == tab
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(width: SightTheme.sidebarWidth)
        .background(SightTheme.sidebarBackground)
    }
    
    // MARK: - Logo Area
    
    private var logoArea: some View {
        VStack(spacing: 8) {
            // Logo with glow effect
            ZStack {
                // Glow
                Circle()
                    .fill(SightTheme.accent.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: logoGlow ? 20 : 10)
                    .scaleEffect(logoGlow ? 1.1 : 1.0)
                
                // Logo
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .frame(width: 64, height: 64)
                    .shadow(color: SightTheme.shadowMedium, radius: 8, x: 0, y: 4)
                
                Image(systemName: "eye.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(SightTheme.sidebarBackground)
            }
            
            Text("Sight")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SightTheme.accentGradient)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .onAppear {
            withAnimation(SightTheme.breathingAnimation) {
                logoGlow = true
            }
        }
    }
    
    // MARK: - Content Area
    
    private var contentArea: some View {
        Group {
            switch selectedTab {
            case .general:
                SightGeneralView()
            case .breaks:
                SightBreaksView()
            case .wellnessReminders:
                SightWellnessRemindersView()
            case .achievements:
                SightAchievementsView()
            case .statistics:
                SightStatisticsView()
            case .shortcuts:
                SightShortcutsView()
            case .about:
                SightAboutView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SightPreferencesView()
}

