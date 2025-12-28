import Foundation

// MARK: - Break Profile

/// Predefined break configuration profiles for different work styles
public enum BreakProfile: String, CaseIterable, Codable {
    case deepWork = "Deep Work"
    case creative = "Creative"
    case evening = "Evening"
    case custom = "Custom"
    
    /// Profile icon
    public var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .creative: return "paintbrush"
        case .evening: return "moon.stars"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    /// Profile accent color name
    public var colorName: String {
        switch self {
        case .deepWork: return "purple"
        case .creative: return "orange"
        case .evening: return "indigo"
        case .custom: return "blue"
        }
    }
    
    /// Profile description
    public var description: String {
        switch self {
        case .deepWork:
            return "Long focus periods for intense concentration"
        case .creative:
            return "Balanced intervals for creative flow"
        case .evening:
            return "Shorter sessions for winding down"
        case .custom:
            return "Your personalized settings"
        }
    }
    
    /// Work interval in seconds
    public var workInterval: Int {
        switch self {
        case .deepWork: return 45 * 60  // 45 minutes
        case .creative: return 25 * 60  // 25 minutes (Pomodoro)
        case .evening: return 15 * 60   // 15 minutes
        case .custom: return PreferencesManager.shared.workIntervalSeconds
        }
    }
    
    /// Break duration in seconds
    public var breakDuration: Int {
        switch self {
        case .deepWork: return 5 * 60   // 5 minutes
        case .creative: return 5 * 60   // 5 minutes
        case .evening: return 2 * 60    // 2 minutes
        case .custom: return PreferencesManager.shared.breakDurationSeconds
        }
    }
    
    /// Pre-break warning in seconds
    public var preBreakWarning: Int {
        switch self {
        case .deepWork: return 30
        case .creative: return 15
        case .evening: return 10
        case .custom: return PreferencesManager.shared.preBreakSeconds
        }
    }
    
    /// Recommended use case
    public var useCase: String {
        switch self {
        case .deepWork: return "Coding, writing, analysis"
        case .creative: return "Design, brainstorming, art"
        case .evening: return "Light work, browsing, email"
        case .custom: return "Your preferences"
        }
    }
}

// MARK: - Profile Configuration

public struct ProfileConfiguration {
    public let workInterval: Int
    public let breakDuration: Int
    public let preBreakWarning: Int
    
    public init(from profile: BreakProfile) {
        self.workInterval = profile.workInterval
        self.breakDuration = profile.breakDuration
        self.preBreakWarning = profile.preBreakWarning
    }
}
