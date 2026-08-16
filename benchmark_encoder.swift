import Foundation

struct FloatingCounterParams: Codable {
    let x: Double
    let y: Double
    let title: String
    let subtitle: String
}

func benchmarkEncoding(iterations: Int) {
    let params = FloatingCounterParams(x: 100.0, y: 200.0, title: "Test", subtitle: "Testing")

    // Baseline: Creating encoder each time
    let startBaseline = Date()
    for _ in 0..<iterations {
        _ = try? JSONEncoder().encode(params)
    }
    let baselineDuration = Date().timeIntervalSince(startBaseline)

    // Optimized: Reusing encoder
    let startOptimized = Date()
    let encoder = JSONEncoder()
    for _ in 0..<iterations {
        _ = try? encoder.encode(params)
    }
    let optimizedDuration = Date().timeIntervalSince(startOptimized)

    print("Baseline (create each time): \(baselineDuration * 1000) ms")
    print("Optimized (reuse encoder): \(optimizedDuration * 1000) ms")
    print("Improvement: \( (1 - optimizedDuration / baselineDuration) * 100 )%")
}

benchmarkEncoding(iterations: 100000)
