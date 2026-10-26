import Combine
import Foundation
import IOKit.ps
import os.log

// MARK: - System Metrics

/// Current system resource metrics
public struct SystemMetrics: Codable {
    public let timestamp: Date
    public let cpuUsage: Double  // 0-100%
    public let batteryLevel: Int  // 0-100%
    public let isOnBattery: Bool
    public let thermalState: ThermalLevel
    public let memoryPressure: MemoryPressure

    public enum ThermalLevel: String, Codable {
        case nominal
        case fair
        case serious
        case critical
    }

    public enum MemoryPressure: String, Codable {
        case normal
        case warning
        case critical
    }
}

// MARK: - Quality Tier

/// Effect quality tiers for adaptive LOD
public enum QualityTier: Int, CaseIterable, Codable, Comparable {
    case ultra = 4
    case high = 3
    case medium = 2
    case low = 1
    case minimal = 0

    public static func < (lhs: QualityTier, rhs: QualityTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .ultra: return "Ultra"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .minimal: return "Minimal"
        }
    }

    public func stepDown() -> QualityTier {
        QualityTier(rawValue: max(rawValue - 1, 0)) ?? .minimal
    }

    public func stepUp() -> QualityTier {
        QualityTier(rawValue: min(rawValue + 1, QualityTier.ultra.rawValue)) ?? .ultra
    }
}

// MARK: - Throttle Thresholds

/// Configurable thresholds for auto-throttling
public struct ThrottleThresholds: Codable {
    /// CPU usage % that triggers throttle down
    public var cpuThrottleDown: Double = 15.0

    /// CPU usage % that allows throttle up
    public var cpuThrottleUp: Double = 10.0

    /// Battery % that triggers throttle down
    public var batteryThrottleDown: Int = 20

    /// Battery % that allows throttle up
    public var batteryThrottleUp: Int = 30

    /// Minimum time between tier changes (seconds)
    public var hysteresisDuration: TimeInterval = 30.0

    /// Number of consecutive samples before changing tier
    public var consecutiveSamplesRequired: Int = 2

    public static let `default` = ThrottleThresholds()

    /// Recommended thresholds for different use cases
    public static let aggressive = ThrottleThresholds(
        cpuThrottleDown: 10.0,
        cpuThrottleUp: 5.0,
        batteryThrottleDown: 30,
        batteryThrottleUp: 40
    )

    public static let relaxed = ThrottleThresholds(
        cpuThrottleDown: 25.0,
        cpuThrottleUp: 15.0,
        batteryThrottleDown: 15,
        batteryThrottleUp: 25
    )
}

// MARK: - Profiler Configuration

/// Configuration for the runtime profiler
public struct ProfilerConfig: Codable {
    /// Sampling interval in seconds
    public var samplingInterval: TimeInterval = 30.0

    /// Enable detailed CPU profiling
    public var detailedCPU: Bool = false

    /// Enable power metrics
    public var trackPower: Bool = true

    /// Maximum samples to retain in memory
    public var maxSampleHistory: Int = 120  // 1 hour at 30s intervals

    /// Throttle thresholds
    public var thresholds: ThrottleThresholds = .default

    /// Enable telemetry export (opt-in)
    public var telemetryEnabled: Bool = false

    public static let `default` = ProfilerConfig()
}

// MARK: - Telemetry Event

/// Anonymized telemetry event for opt-in metrics
public struct TelemetryEvent: Codable {
    public let sessionId: String  // Random UUID per session
    public let timestamp: Date
    public let eventType: EventType
    public let qualityTier: QualityTier
    public let metrics: MetricsSummary

    public enum EventType: String, Codable {
        case tierChange
        case sessionStart
        case sessionEnd
        case periodic
    }

    public struct MetricsSummary: Codable {
        public let avgCPU: Double
        public let minBattery: Int
        public let thermalEvents: Int
        public let throttleEvents: Int
    }
}

// MARK: - Anonymized Metrics Schema

/*
 Anonymized Metrics Schema (Opt-In Only)
 ========================================

 All telemetry is:
 - Opt-in only (config.telemetryEnabled)
 - Anonymized (no device IDs, user IDs, or PII)
 - Session-scoped (new UUID each launch)

 Schema:
 {
   "schema_version": "1.0",
   "session_id": "random-uuid-per-session",
   "events": [
     {
       "timestamp": "ISO8601",
       "event_type": "tierChange|sessionStart|sessionEnd|periodic",
       "quality_tier": "ultra|high|medium|low|minimal",
       "metrics": {
         "avg_cpu": 12.5,
         "min_battery": 45,
         "thermal_events": 0,
         "throttle_events": 2
       }
     }
   ],
   "summary": {
     "session_duration_seconds": 3600,
     "avg_quality_tier": 2.5,
     "total_throttle_downs": 3,
     "total_throttle_ups": 2
   }
 }

 Export pseudocode:
 -----------------
 func exportTelemetry():
     if not config.telemetryEnabled:
         return

     events = profiler.collectAnonymizedEvents()
     summary = profiler.generateSummary()

     payload = {
         "schema_version": "1.0",
         "session_id": sessionId,
         "events": events,
         "summary": summary
     }

     // Queue for batch upload
     telemetryQueue.enqueue(payload)

     // Upload when network available and app backgrounded
     if canUpload():
         httpClient.post(TELEMETRY_ENDPOINT, payload)
*/

// MARK: - Runtime Profiler

/// Lightweight runtime profiler for CPU/Battery monitoring and adaptive LOD
public final class RuntimeProfiler: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var currentMetrics: SystemMetrics?
    @Published public private(set) var currentTier: QualityTier = .high
    @Published public private(set) var isThrottled: Bool = false

    // MARK: - Configuration

    public var config: ProfilerConfig {
        didSet { updateSamplingInterval() }
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.kumargaurav.Sight.profiler", category: "RuntimeProfiler")
    private var samplingTimer: DispatchSourceTimer?
    private let samplingQueue = DispatchQueue(label: "com.sight.profiler.sampling", qos: .utility)

    private var sampleHistory: [SystemMetrics] = []
    private var consecutiveThrottleDownSamples = 0
    private var consecutiveThrottleUpSamples = 0
    private var lastTierChangeTime: Date?

    // Telemetry
    private var telemetryEvents: [TelemetryEvent] = []
    private let sessionId = UUID().uuidString
    private var throttleDownCount = 0
    private var throttleUpCount = 0

    // Callbacks
    public var onTierChange: ((QualityTier, QualityTier) -> Void)?
    public var onThrottle: ((Bool) -> Void)?

    // MARK: - Singleton

    public static let shared = RuntimeProfiler()

    // MARK: - Initialization

    public init(config: ProfilerConfig = .default) {
        self.config = config
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    /// Start profiling
    public func start() {
        logger.info("Starting runtime profiler (interval: \(self.config.samplingInterval)s)")

        recordTelemetryEvent(.sessionStart)
        startSamplingTimer()
    }

    /// Stop profiling
    public func stop() {
        samplingTimer?.cancel()
        samplingTimer = nil

        recordTelemetryEvent(.sessionEnd)
        logger.info("Stopped runtime profiler")
    }

    /// Force a quality tier (bypasses auto-throttle)
    public func forceQualityTier(_ tier: QualityTier) {
        let oldTier = currentTier
        currentTier = tier

        if oldTier != tier {
            logger.info("Forced tier change: \(oldTier.description) → \(tier.description)")
            onTierChange?(oldTier, tier)
        }
    }

    /// Reset to default tier
    public func resetToDefault() {
        forceQualityTier(.high)
        isThrottled = false
        consecutiveThrottleDownSamples = 0
        consecutiveThrottleUpSamples = 0
    }

    /// Get recommended thresholds description
    public static var recommendedThresholds: String {
        """
        Recommended Thresholds:
        ━━━━━━━━━━━━━━━━━━━━━━━
        CPU Throttle Down: >15%
        CPU Throttle Up:   <10%
        Battery Down:      <20%
        Battery Up:        >30%
        Hysteresis:        30 seconds
        Samples Required:  2 consecutive

        These thresholds balance:
        - User experience (smooth effects)
        - Battery life (power efficiency)
        - Thermal management (prevent throttling)
        """
    }

    // MARK: - Sampling Timer

    private func startSamplingTimer() {
        samplingTimer?.cancel()

        samplingTimer = DispatchSource.makeTimerSource(queue: samplingQueue)
        samplingTimer?.schedule(
            deadline: .now(),
            repeating: config.samplingInterval
        )
        samplingTimer?.setEventHandler { [weak self] in
            self?.sample()
        }
        samplingTimer?.resume()
    }

    private func updateSamplingInterval() {
        if samplingTimer != nil {
            startSamplingTimer()
        }
    }

    // MARK: - Sampling

    private func sample() {
        let metrics = collectMetrics()

        DispatchQueue.main.async {
            self.currentMetrics = metrics
            self.addToHistory(metrics)
            self.evaluateThrottling(metrics)
        }
    }

    private func collectMetrics() -> SystemMetrics {
        return SystemMetrics(
            timestamp: Date(),
            cpuUsage: getCPUUsage(),
            batteryLevel: getBatteryLevel(),
            isOnBattery: isOnBatteryPower(),
            thermalState: getThermalState(),
            memoryPressure: getMemoryPressure()
        )
    }

    private func addToHistory(_ metrics: SystemMetrics) {
        sampleHistory.append(metrics)

        // Trim to max history
        if sampleHistory.count > config.maxSampleHistory {
            sampleHistory.removeFirst(sampleHistory.count - config.maxSampleHistory)
        }
    }

    // MARK: - Throttling Logic

    private func evaluateThrottling(_ metrics: SystemMetrics) {
        let thresholds = config.thresholds

        // Check if we should throttle down
        let shouldThrottleDown =
            metrics.cpuUsage > thresholds.cpuThrottleDown
            || (metrics.isOnBattery && metrics.batteryLevel < thresholds.batteryThrottleDown)
            || metrics.thermalState == .serious || metrics.thermalState == .critical

        // Check if we can throttle up
        let canThrottleUp =
            metrics.cpuUsage < thresholds.cpuThrottleUp
            && (!metrics.isOnBattery || metrics.batteryLevel > thresholds.batteryThrottleUp)
            && metrics.thermalState == .nominal

        // Apply hysteresis
        if let lastChange = lastTierChangeTime,
            Date().timeIntervalSince(lastChange) < thresholds.hysteresisDuration
        {
            return
        }

        // Count consecutive samples
        if shouldThrottleDown {
            consecutiveThrottleDownSamples += 1
            consecutiveThrottleUpSamples = 0
        } else if canThrottleUp && isThrottled {
            consecutiveThrottleUpSamples += 1
            consecutiveThrottleDownSamples = 0
        } else {
            consecutiveThrottleDownSamples = 0
            consecutiveThrottleUpSamples = 0
        }

        // Apply throttle changes
        if consecutiveThrottleDownSamples >= thresholds.consecutiveSamplesRequired {
            throttleDown()
        } else if consecutiveThrottleUpSamples >= thresholds.consecutiveSamplesRequired {
            throttleUp()
        }
    }

    private func throttleDown() {
        guard currentTier > .minimal else { return }

        let oldTier = currentTier
        currentTier = currentTier.stepDown()
        isThrottled = true
        lastTierChangeTime = Date()
        consecutiveThrottleDownSamples = 0
        throttleDownCount += 1

        logger.warning("Throttle DOWN: \(oldTier.description) → \(self.currentTier.description)")

        onTierChange?(oldTier, currentTier)
        onThrottle?(true)
        recordTelemetryEvent(.tierChange)
    }

    private func throttleUp() {
        guard currentTier < .high else {
            isThrottled = false
            return
        }

        let oldTier = currentTier
        currentTier = currentTier.stepUp()
        lastTierChangeTime = Date()
        consecutiveThrottleUpSamples = 0
        throttleUpCount += 1

        if currentTier >= .high {
            isThrottled = false
        }

        logger.info("Throttle UP: \(oldTier.description) → \(self.currentTier.description)")

        onTierChange?(oldTier, currentTier)
        onThrottle?(false)
        recordTelemetryEvent(.tierChange)
    }

    // MARK: - System Metrics Collection

    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        // SECURITY: Explicit check for both success AND valid pointer
        guard result == KERN_SUCCESS else {
            return 0
        }

        guard let info = cpuInfo else {
            return 0
        }

        // SECURITY: Defer deallocation to ensure it happens on all exit paths
        defer {
            let size = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<Int32>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        var totalUser: Int32 = 0
        var totalSystem: Int32 = 0
        var totalIdle: Int32 = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += info[offset + Int(CPU_STATE_USER)]
            totalSystem += info[offset + Int(CPU_STATE_SYSTEM)]
            totalIdle += info[offset + Int(CPU_STATE_IDLE)]
        }

        let total = totalUser + totalSystem + totalIdle
        guard total > 0 else { return 0 }

        let usage = Double(totalUser + totalSystem) / Double(total) * 100.0

        return usage
    }

    private func getBatteryLevel() -> Int {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue()
                as? [String: Any],
                let capacity = info[kIOPSCurrentCapacityKey] as? Int
            {
                return capacity
            }
        }

        return 100  // Assume full if can't read
    }

    private func isOnBatteryPower() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue()
                as? [String: Any],
                let powerSource = info[kIOPSPowerSourceStateKey] as? String
            {
                return powerSource == kIOPSBatteryPowerValue
            }
        }

        return false
    }

    private func getThermalState() -> SystemMetrics.ThermalLevel {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }

    private func getMemoryPressure() -> SystemMetrics.MemoryPressure {
        // Use dispatch source for memory pressure
        // For now, return normal
        return .normal
    }

    // MARK: - Telemetry

    private func recordTelemetryEvent(_ type: TelemetryEvent.EventType) {
        guard config.telemetryEnabled else { return }

        let summary = generateMetricsSummary()
        let event = TelemetryEvent(
            sessionId: sessionId,
            timestamp: Date(),
            eventType: type,
            qualityTier: currentTier,
            metrics: summary
        )

        telemetryEvents.append(event)

        // SECURITY: Limit telemetry events to prevent unbounded memory growth
        let maxTelemetryEvents = 1000
        if telemetryEvents.count > maxTelemetryEvents {
            telemetryEvents.removeFirst(telemetryEvents.count - maxTelemetryEvents)
        }

        // Periodic export check
        if type == .periodic || type == .sessionEnd {
            exportTelemetryIfNeeded()
        }
    }

    private func generateMetricsSummary() -> TelemetryEvent.MetricsSummary {
        let recentHistory = sampleHistory.suffix(10)

        let avgCPU =
            recentHistory.isEmpty
            ? 0 : recentHistory.reduce(0.0) { $0 + $1.cpuUsage } / Double(recentHistory.count)

        let minBattery =
            recentHistory.min(by: { $0.batteryLevel < $1.batteryLevel })?.batteryLevel ?? 100

        let thermalEvents = recentHistory.filter {
            $0.thermalState == .serious || $0.thermalState == .critical
        }.count

        return TelemetryEvent.MetricsSummary(
            avgCPU: avgCPU,
            minBattery: minBattery,
            thermalEvents: thermalEvents,
            throttleEvents: throttleDownCount + throttleUpCount
        )
    }

    private func exportTelemetryIfNeeded() {
        // Pseudocode: Queue telemetry for batch upload
        // In production, implement actual upload logic
        logger.debug("Telemetry queued: \(self.telemetryEvents.count) events")
    }

    /// Get anonymized telemetry for export
    public func getAnonymizedTelemetry() -> Data? {
        guard config.telemetryEnabled else { return nil }

        let payload: [String: Any] = [
            "schema_version": "1.0",
            "session_id": sessionId,
            "events": telemetryEvents.map { event -> [String: Any] in
                [
                    "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
                    "event_type": event.eventType.rawValue,
                    "quality_tier": event.qualityTier.description,
                    "metrics": [
                        "avg_cpu": event.metrics.avgCPU,
                        "min_battery": event.metrics.minBattery,
                        "thermal_events": event.metrics.thermalEvents,
                        "throttle_events": event.metrics.throttleEvents,
                    ],
                ]
            },
            "summary": [
                "throttle_downs": throttleDownCount,
                "throttle_ups": throttleUpCount,
            ],
        ]

        return try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
    }
}

// MARK: - Quality Tier Extension for Overlay

extension QualityTier {
    /// Convert to OverlayQualityTier
    public var overlayTier: OverlayQualityTier {
        switch self {
        case .ultra, .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .minimal: return .minimal
        }
    }
}
