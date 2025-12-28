import XCTest
@testable import Sight

final class RuntimeProfilerTests: XCTestCase {
    
    // MARK: - Quality Tier Tests
    
    func testQualityTierOrdering() {
        XCTAssertLessThan(QualityTier.minimal, QualityTier.low)
        XCTAssertLessThan(QualityTier.low, QualityTier.medium)
        XCTAssertLessThan(QualityTier.medium, QualityTier.high)
        XCTAssertLessThan(QualityTier.high, QualityTier.ultra)
    }
    
    func testQualityTierStepDown() {
        XCTAssertEqual(QualityTier.ultra.stepDown(), .high)
        XCTAssertEqual(QualityTier.high.stepDown(), .medium)
        XCTAssertEqual(QualityTier.medium.stepDown(), .low)
        XCTAssertEqual(QualityTier.low.stepDown(), .minimal)
        XCTAssertEqual(QualityTier.minimal.stepDown(), .minimal) // Can't go lower
    }
    
    func testQualityTierStepUp() {
        XCTAssertEqual(QualityTier.minimal.stepUp(), .low)
        XCTAssertEqual(QualityTier.low.stepUp(), .medium)
        XCTAssertEqual(QualityTier.medium.stepUp(), .high)
        XCTAssertEqual(QualityTier.high.stepUp(), .ultra)
        XCTAssertEqual(QualityTier.ultra.stepUp(), .ultra) // Can't go higher
    }
    
    func testQualityTierDescriptions() {
        XCTAssertEqual(QualityTier.ultra.description, "Ultra")
        XCTAssertEqual(QualityTier.high.description, "High")
        XCTAssertEqual(QualityTier.medium.description, "Medium")
        XCTAssertEqual(QualityTier.low.description, "Low")
        XCTAssertEqual(QualityTier.minimal.description, "Minimal")
    }
    
    func testQualityTierCodable() throws {
        for tier in QualityTier.allCases {
            let data = try JSONEncoder().encode(tier)
            let decoded = try JSONDecoder().decode(QualityTier.self, from: data)
            XCTAssertEqual(decoded, tier)
        }
    }
    
    // MARK: - Throttle Thresholds Tests
    
    func testDefaultThresholds() {
        let thresholds = ThrottleThresholds.default
        XCTAssertEqual(thresholds.cpuThrottleDown, 15.0)
        XCTAssertEqual(thresholds.cpuThrottleUp, 10.0)
        XCTAssertEqual(thresholds.batteryThrottleDown, 20)
        XCTAssertEqual(thresholds.batteryThrottleUp, 30)
        XCTAssertEqual(thresholds.hysteresisDuration, 30.0)
        XCTAssertEqual(thresholds.consecutiveSamplesRequired, 2)
    }
    
    func testAggressiveThresholds() {
        let thresholds = ThrottleThresholds.aggressive
        XCTAssertEqual(thresholds.cpuThrottleDown, 10.0)
        XCTAssertEqual(thresholds.batteryThrottleDown, 30)
    }
    
    func testRelaxedThresholds() {
        let thresholds = ThrottleThresholds.relaxed
        XCTAssertEqual(thresholds.cpuThrottleDown, 25.0)
        XCTAssertEqual(thresholds.batteryThrottleDown, 15)
    }
    
    func testThresholdsCodable() throws {
        let thresholds = ThrottleThresholds.default
        let data = try JSONEncoder().encode(thresholds)
        let decoded = try JSONDecoder().decode(ThrottleThresholds.self, from: data)
        
        XCTAssertEqual(decoded.cpuThrottleDown, thresholds.cpuThrottleDown)
        XCTAssertEqual(decoded.batteryThrottleDown, thresholds.batteryThrottleDown)
    }
    
    // MARK: - Profiler Config Tests
    
    func testDefaultProfilerConfig() {
        let config = ProfilerConfig.default
        XCTAssertEqual(config.samplingInterval, 30.0)
        XCTAssertFalse(config.detailedCPU)
        XCTAssertTrue(config.trackPower)
        XCTAssertEqual(config.maxSampleHistory, 120)
        XCTAssertFalse(config.telemetryEnabled)
    }
    
    func testProfilerConfigCodable() throws {
        var config = ProfilerConfig.default
        config.telemetryEnabled = true
        config.samplingInterval = 60.0
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ProfilerConfig.self, from: data)
        
        XCTAssertEqual(decoded.telemetryEnabled, true)
        XCTAssertEqual(decoded.samplingInterval, 60.0)
    }
    
    // MARK: - System Metrics Tests
    
    func testSystemMetricsThermalLevel() {
        for level in [SystemMetrics.ThermalLevel.nominal, .fair, .serious, .critical] {
            let data = try! JSONEncoder().encode(level)
            let decoded = try! JSONDecoder().decode(SystemMetrics.ThermalLevel.self, from: data)
            XCTAssertEqual(decoded, level)
        }
    }
    
    func testSystemMetricsMemoryPressure() {
        for pressure in [SystemMetrics.MemoryPressure.normal, .warning, .critical] {
            let data = try! JSONEncoder().encode(pressure)
            let decoded = try! JSONDecoder().decode(SystemMetrics.MemoryPressure.self, from: data)
            XCTAssertEqual(decoded, pressure)
        }
    }
    
    // MARK: - Telemetry Event Tests
    
    func testTelemetryEventTypes() {
        for type in [TelemetryEvent.EventType.tierChange, .sessionStart, .sessionEnd, .periodic] {
            let data = try! JSONEncoder().encode(type)
            let decoded = try! JSONDecoder().decode(TelemetryEvent.EventType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }
    
    func testTelemetryMetricsSummaryCodable() throws {
        let summary = TelemetryEvent.MetricsSummary(
            avgCPU: 12.5,
            minBattery: 45,
            thermalEvents: 2,
            throttleEvents: 3
        )
        
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(TelemetryEvent.MetricsSummary.self, from: data)
        
        XCTAssertEqual(decoded.avgCPU, 12.5)
        XCTAssertEqual(decoded.minBattery, 45)
        XCTAssertEqual(decoded.thermalEvents, 2)
        XCTAssertEqual(decoded.throttleEvents, 3)
    }
    
    // MARK: - Profiler Manager Tests
    
    func testProfilerSharedInstance() {
        let profiler = RuntimeProfiler.shared
        XCTAssertNotNil(profiler)
    }
    
    func testProfilerInitialState() {
        let profiler = RuntimeProfiler()
        XCTAssertEqual(profiler.currentTier, .high)
        XCTAssertFalse(profiler.isThrottled)
        XCTAssertNil(profiler.currentMetrics)
    }
    
    func testProfilerForceQualityTier() {
        let profiler = RuntimeProfiler()
        
        profiler.forceQualityTier(.low)
        XCTAssertEqual(profiler.currentTier, .low)
        
        profiler.forceQualityTier(.ultra)
        XCTAssertEqual(profiler.currentTier, .ultra)
    }
    
    func testProfilerResetToDefault() {
        let profiler = RuntimeProfiler()
        
        profiler.forceQualityTier(.minimal)
        XCTAssertEqual(profiler.currentTier, .minimal)
        
        profiler.resetToDefault()
        XCTAssertEqual(profiler.currentTier, .high)
        XCTAssertFalse(profiler.isThrottled)
    }
    
    func testProfilerRecommendedThresholds() {
        let text = RuntimeProfiler.recommendedThresholds
        XCTAssertTrue(text.contains("CPU Throttle Down: >15%"))
        XCTAssertTrue(text.contains("Battery Down:      <20%"))
    }
    
    // MARK: - Quality Tier to Overlay Tier Conversion
    
    func testQualityTierToOverlayTier() {
        XCTAssertEqual(QualityTier.ultra.overlayTier, .high)
        XCTAssertEqual(QualityTier.high.overlayTier, .high)
        XCTAssertEqual(QualityTier.medium.overlayTier, .medium)
        XCTAssertEqual(QualityTier.low.overlayTier, .low)
        XCTAssertEqual(QualityTier.minimal.overlayTier, .minimal)
    }
    
    // MARK: - Telemetry Export Tests
    
    func testTelemetryDisabledByDefault() {
        let profiler = RuntimeProfiler()
        XCTAssertNil(profiler.getAnonymizedTelemetry())
    }
    
    func testTelemetryEnabledExport() {
        var config = ProfilerConfig.default
        config.telemetryEnabled = true
        let profiler = RuntimeProfiler(config: config)
        
        // Should return data when enabled (even if empty)
        let data = profiler.getAnonymizedTelemetry()
        XCTAssertNotNil(data)
        
        // Verify JSON structure
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["schema_version"] as? String, "1.0")
            XCTAssertNotNil(json["session_id"])
            XCTAssertNotNil(json["events"])
        }
    }
}
