import Foundation

/// Configuration for timer intervals
public struct TimerConfiguration: Codable, Equatable {
    
    // MARK: - Timer Mode
    
    public enum TimerMode: String, Codable, CaseIterable {
        case eyeCare = "20-20-20 Rule"      // 20 min work, 20 sec break
        case custom = "Custom"
    }
    
    /// Current timer mode
    public var mode: TimerMode
    
    // MARK: - Basic Settings
    
    /// Work interval in seconds
    public var workIntervalSeconds: Int
    
    /// Pre-break warning duration in seconds
    public var preBreakSeconds: Int
    
    /// Short break duration in seconds
    public var breakDurationSeconds: Int
    
    /// Adaptive mode - adjusts timing based on context
    public var adaptiveMode: Bool
    
    // MARK: - Initialization
    
    public init(
        mode: TimerMode = .eyeCare,
        workIntervalSeconds: Int = 20 * 60,
        preBreakSeconds: Int = 10,
        breakDurationSeconds: Int = 20,
        adaptiveMode: Bool = false
    ) {
        self.mode = mode
        self.workIntervalSeconds = workIntervalSeconds
        self.preBreakSeconds = preBreakSeconds
        self.breakDurationSeconds = breakDurationSeconds
        self.adaptiveMode = adaptiveMode
    }
    
    // MARK: - Presets
    
    /// Default: 20-20-20 eye care rule
    public static let `default` = TimerConfiguration()
    
    /// Debug configuration with shorter intervals
    public static let debug = TimerConfiguration(
        mode: .eyeCare,
        workIntervalSeconds: 10,
        preBreakSeconds: 3,
        breakDurationSeconds: 5
    )
}
