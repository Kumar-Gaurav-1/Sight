import Foundation
import CoreGraphics

// MARK: - Break Style

/// Visual style for break overlay
public enum BreakStyle: String, Codable, CaseIterable {
    case calm      // Blue tones, slow breathing
    case focus     // Purple tones, medium breathing
    case energize  // Orange tones, faster breathing
    
    var sceneStyleKey: String {
        return rawValue
    }
}

// MARK: - Floating Counter Parameters

/// Parameters for the floating counter widget
public struct FloatingCounterParams: Codable {
    /// Screen position (0-1 normalized)
    public var position: CGPoint
    
    /// Whether to show the widget
    public var visible: Bool
    
    /// Current state to display
    public var state: TimerState
    
    /// Formatted time string
    public var formattedTime: String
    
    public init(
        position: CGPoint = CGPoint(x: 0.95, y: 0.05),
        visible: Bool = true,
        state: TimerState = .idle,
        formattedTime: String = "00:00"
    ) {
        self.position = position
        self.visible = visible
        self.state = state
        self.formattedTime = formattedTime
    }
}

// MARK: - Renderer API Protocol

/// RPC-like API contract for the Anigravity Renderer
/// Implementations can use XPC, Unix sockets, or in-process rendering
public protocol RendererAPI {
    /// Show pre-break warning HUD that follows cursor
    /// - Parameter preSeconds: Countdown seconds to display
    func showPreBreak(preSeconds: Int)
    
    /// Show full-screen break overlay with blur and animation
    /// - Parameters:
    ///   - duration: Break duration in seconds
    ///   - style: Visual style for the break
    func showBreak(duration: Int, style: BreakStyle)
    
    /// Show floating counter widget
    /// - Parameter params: Widget configuration
    func showFloatingCounter(params: FloatingCounterParams)
    
    /// Update the countdown display
    /// - Parameter remainingSeconds: Current countdown value
    func updateCountdown(remainingSeconds: Int)
    
    /// Show a specific micro-nudge (e.g. posture, blink)
    /// - Parameter type: The type of nudge to display
    func showNudge(type: NudgeType)
    
    /// Hides all overlays and widgets
    func hide()
    
    /// Check if renderer is available
    var isAvailable: Bool { get }
}

// MARK: - Renderer Message (IPC)

/// Messages sent over IPC to the renderer process
public enum RendererMessage: Codable {
    case showPreBreak(preSeconds: Int)
    case showBreak(duration: Int, style: BreakStyle)
    case showFloatingCounter(params: FloatingCounterParams)
    case showNudge(type: NudgeType)
    case updateCountdown(remainingSeconds: Int)
    case hide
    case ping
    
    // Coding keys for clean JSON serialization
    private enum CodingKeys: String, CodingKey {
        case type, preSeconds, duration, style, params, remainingSeconds, nudgeType
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "showPreBreak":
            let preSeconds = try container.decode(Int.self, forKey: .preSeconds)
            self = .showPreBreak(preSeconds: preSeconds)
        case "showBreak":
            let duration = try container.decode(Int.self, forKey: .duration)
            let style = try container.decode(BreakStyle.self, forKey: .style)
            self = .showBreak(duration: duration, style: style)
        case "showFloatingCounter":
            let params = try container.decode(FloatingCounterParams.self, forKey: .params)
            self = .showFloatingCounter(params: params)
        case "showNudge":
            let nudgeType = try container.decode(NudgeType.self, forKey: .nudgeType)
            self = .showNudge(type: nudgeType)
        case "updateCountdown":
            let remainingSeconds = try container.decode(Int.self, forKey: .remainingSeconds)
            self = .updateCountdown(remainingSeconds: remainingSeconds)
        case "hide":
            self = .hide
        case "ping":
            self = .ping
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown message type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .showPreBreak(let preSeconds):
            try container.encode("showPreBreak", forKey: .type)
            try container.encode(preSeconds, forKey: .preSeconds)
        case .showBreak(let duration, let style):
            try container.encode("showBreak", forKey: .type)
            try container.encode(duration, forKey: .duration)
            try container.encode(style, forKey: .style)
        case .showFloatingCounter(let params):
            try container.encode("showFloatingCounter", forKey: .type)
            try container.encode(params, forKey: .params)
        case .showNudge(let type):
            try container.encode("showNudge", forKey: .type)
            try container.encode(type, forKey: .nudgeType)
        case .updateCountdown(let remainingSeconds):
            try container.encode("updateCountdown", forKey: .type)
            try container.encode(remainingSeconds, forKey: .remainingSeconds)
        case .hide:
            try container.encode("hide", forKey: .type)
        case .ping:
            try container.encode("ping", forKey: .type)
        }
    }
}

// MARK: - Scene Configuration

/// Configuration loaded from scene JSON files
public struct SceneConfiguration: Codable {
    public let scene: SceneInfo
    public let physics: PhysicsConfig?
    public let shaders: [String: ShaderConfig]?
    public let lod: [String: LODConfig]?
    
    public struct SceneInfo: Codable {
        public let name: String
        public let version: String
        public let type: String
        public let behavior: String
    }
    
    public struct PhysicsConfig: Codable {
        public let spring: SpringConfig?
        
        public struct SpringConfig: Codable {
            public let stiffness: Float
            public let damping: Float
            public let mass: Float
        }
    }
    
    public struct ShaderConfig: Codable {
        public let type: String
        public let level: Float?
    }
    
    public struct LODConfig: Codable {
        public let shadowEnabled: Bool?
        public let animationsEnabled: Bool?
        public let refreshRate: Int?
        public let blurRadius: Int?
    }
}
