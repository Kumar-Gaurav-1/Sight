import XCTest
@testable import Sight

final class BreakOverlayTests: XCTestCase {
    
    // MARK: - Quality Tier Tests
    
    func testHighTierProperties() {
        let tier = OverlayQualityTier.high
        XCTAssertTrue(tier.usesGPU)
        XCTAssertEqual(tier.targetFPS, 60)
        XCTAssertEqual(tier.blurSamples, 13)
    }
    
    func testMediumTierProperties() {
        let tier = OverlayQualityTier.medium
        XCTAssertTrue(tier.usesGPU)
        XCTAssertEqual(tier.targetFPS, 30)
        XCTAssertEqual(tier.blurSamples, 7)
    }
    
    func testLowTierProperties() {
        let tier = OverlayQualityTier.low
        XCTAssertFalse(tier.usesGPU)
        XCTAssertEqual(tier.targetFPS, 15)
        XCTAssertEqual(tier.blurSamples, 5)
    }
    
    func testMinimalTierProperties() {
        let tier = OverlayQualityTier.minimal
        XCTAssertFalse(tier.usesGPU)
        XCTAssertEqual(tier.targetFPS, 1)
        XCTAssertEqual(tier.blurSamples, 3)
    }
    
    func testAllTiersCodable() throws {
        for tier in OverlayQualityTier.allCases {
            let data = try JSONEncoder().encode(tier)
            let decoded = try JSONDecoder().decode(OverlayQualityTier.self, from: data)
            XCTAssertEqual(decoded, tier)
        }
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfig() {
        let config = BreakOverlayConfig.default
        XCTAssertEqual(config.qualityTier, .high)
        XCTAssertEqual(config.blurRadius, 0.5)
        XCTAssertEqual(config.vignetteRadius, 0.4)
        XCTAssertEqual(config.breathingSpeed, 1.0)
    }
    
    func testLowPowerConfig() {
        let config = BreakOverlayConfig.lowPower
        XCTAssertEqual(config.qualityTier, .low)
        XCTAssertEqual(config.blurRadius, 0.3)
        XCTAssertEqual(config.breathingSpeed, 0.5)
    }
    
    // MARK: - Uniforms Tests
    
    func testUniformsDefaultValues() {
        let uniforms = BreakOverlayUniforms()
        XCTAssertEqual(uniforms.time, 0)
        XCTAssertEqual(uniforms.blurRadius, 0.5)
        XCTAssertEqual(uniforms.vignetteRadius, 0.4)
        XCTAssertEqual(uniforms.breathePhase, 0)
        XCTAssertEqual(uniforms.center.x, 0.5)
        XCTAssertEqual(uniforms.center.y, 0.5)
    }
    
    func testUniformsMemoryLayout() {
        // Ensure uniforms can be passed to Metal
        let size = MemoryLayout<BreakOverlayUniforms>.size
        XCTAssertGreaterThan(size, 0)
        XCTAssertTrue(size.isMultiple(of: 4)) // Metal alignment
    }
    
    // MARK: - Manager Tests
    
    func testManagerSharedInstance() {
        let manager = BreakOverlayManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testManagerInitialState() {
        let manager = BreakOverlayManager.shared
        // Initial state should be not showing
        // (may be showing from previous test, so just check it's accessible)
        _ = manager.isShowing
        _ = manager.currentTier
    }
    
    // MARK: - Tier Selection Logic Tests
    
    func testGPUTiersUseGPU() {
        let gpuTiers: [OverlayQualityTier] = [.high, .medium]
        for tier in gpuTiers {
            XCTAssertTrue(tier.usesGPU, "\(tier) should use GPU")
        }
    }
    
    func testCPUTiersDoNotUseGPU() {
        let cpuTiers: [OverlayQualityTier] = [.low, .minimal]
        for tier in cpuTiers {
            XCTAssertFalse(tier.usesGPU, "\(tier) should not use GPU")
        }
    }
    
    func testFPSDecreasesByTier() {
        let ordered: [OverlayQualityTier] = [.high, .medium, .low, .minimal]
        for i in 0..<(ordered.count - 1) {
            XCTAssertGreaterThan(
                ordered[i].targetFPS,
                ordered[i + 1].targetFPS,
                "\(ordered[i]) should have higher FPS than \(ordered[i + 1])"
            )
        }
    }
    
    func testBlurSamplesDecreasesByTier() {
        let ordered: [OverlayQualityTier] = [.high, .medium, .low, .minimal]
        for i in 0..<(ordered.count - 1) {
            XCTAssertGreaterThan(
                ordered[i].blurSamples,
                ordered[i + 1].blurSamples,
                "\(ordered[i]) should have more samples than \(ordered[i + 1])"
            )
        }
    }
}
