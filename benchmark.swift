import Foundation

// Define mock data
struct TelemetryMetricsSummary {
    let avgCPU: Double
    let minBattery: Double
    let thermalEvents: Int
    let throttleEvents: Int
}

enum EventType: String {
    case test
}

enum QualityTier: CustomStringConvertible {
    case test
    var description: String { return "test" }
}

struct TelemetryEvent {
    let timestamp: Date
    let eventType: EventType
    let qualityTier: QualityTier
    let metrics: TelemetryMetricsSummary
}

let events = (0..<10000).map { _ in
    TelemetryEvent(
        timestamp: Date(),
        eventType: .test,
        qualityTier: .test,
        metrics: TelemetryMetricsSummary(avgCPU: 0.5, minBattery: 0.5, thermalEvents: 0, throttleEvents: 0)
    )
}

func testUnoptimized() -> TimeInterval {
    let start = Date()
    let _ = events.map { event -> [String: Any] in
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
    }
    return Date().timeIntervalSince(start)
}

func testOptimized() -> TimeInterval {
    let start = Date()
    let formatter = ISO8601DateFormatter()
    let _ = events.map { event -> [String: Any] in
        [
            "timestamp": formatter.string(from: event.timestamp),
            "event_type": event.eventType.rawValue,
            "quality_tier": event.qualityTier.description,
            "metrics": [
                "avg_cpu": event.metrics.avgCPU,
                "min_battery": event.metrics.minBattery,
                "thermal_events": event.metrics.thermalEvents,
                "throttle_events": event.metrics.throttleEvents,
            ],
        ]
    }
    return Date().timeIntervalSince(start)
}

print("Running unoptimized...")
let unoptimizedTime = testUnoptimized()
print("Unoptimized time: \(unoptimizedTime) seconds")

print("Running optimized...")
let optimizedTime = testOptimized()
print("Optimized time: \(optimizedTime) seconds")
print("Improvement: \(unoptimizedTime / optimizedTime)x")
