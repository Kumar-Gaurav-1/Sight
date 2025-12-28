import Foundation

/// Timer states for the break reminder cycle
public enum TimerState: String, Codable, CaseIterable {
    /// App is not running a timer
    case idle
    /// User is actively working
    case work
    /// Warning period before break begins
    case preBreak
    /// Break is in progress
    case `break`
    
    /// Human-readable description
    public var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .work: return "Working"
        case .preBreak: return "Break Soon"
        case .break: return "On Break"
        }
    }
    
    /// Menu bar icon name (SF Symbols)
    public var iconName: String {
        switch self {
        case .idle: return "eye"
        case .work: return "eye.fill"
        case .preBreak: return "eye.trianglebadge.exclamationmark"
        case .break: return "eye.slash.fill"
        }
    }
}
