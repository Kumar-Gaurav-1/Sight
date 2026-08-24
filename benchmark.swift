import Foundation

struct TelemetryEvent {
    let timestamp: Date
    let eventType: String
    let qualityTier: String
    struct MetricsSummary {
        let avgCPU: Double
        let minBattery: Int
        let thermalEvents: Int
        let throttleEvents: Int
    }
    let metrics: MetricsSummary
}

let events = (0..<10000).map { i in
    TelemetryEvent(
        timestamp: Date(),
        eventType: "event_\(i)",
        qualityTier: "high",
        metrics: TelemetryEvent.MetricsSummary(avgCPU: 50.0, minBattery: 50, thermalEvents: 0, throttleEvents: 0)
    )
}

func testWithoutOptimization() {
    let start = Date()
    let _ = events.map { event -> [String: Any] in
        [
            "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
            "event_type": event.eventType,
            "quality_tier": event.qualityTier,
            "metrics": [
                "avg_cpu": event.metrics.avgCPU,
                "min_battery": event.metrics.minBattery,
                "thermal_events": event.metrics.thermalEvents,
                "throttle_events": event.metrics.throttleEvents,
            ],
        ]
    }
    let end = Date()
    print("Without optimization: \(end.timeIntervalSince(start)) seconds")
}

func testWithOptimization() {
    let start = Date()
    let dateFormatter = ISO8601DateFormatter()
    let _ = events.map { event -> [String: Any] in
        [
            "timestamp": dateFormatter.string(from: event.timestamp),
            "event_type": event.eventType,
            "quality_tier": event.qualityTier,
            "metrics": [
                "avg_cpu": event.metrics.avgCPU,
                "min_battery": event.metrics.minBattery,
                "thermal_events": event.metrics.thermalEvents,
                "throttle_events": event.metrics.throttleEvents,
            ],
        ]
    }
    let end = Date()
    print("With optimization: \(end.timeIntervalSince(start)) seconds")
}

testWithoutOptimization()
testWithOptimization()
