import Foundation

struct DayStats {
    var breaksCompleted: Int = 1
    var breaksSkipped: Int = 0
    var totalBreakMinutes: Int = 10
    var shortBreaksCompleted: Int = 1
    var longBreaksCompleted: Int = 0
    var dailyScore: Double = 95.0
}

struct AggregatedStats {
    var breaksCompleted: Int = 0
    var breaksSkipped: Int = 0
    var totalBreakMinutes: Int = 0
    var shortBreaksCompleted: Int = 0
    var longBreaksCompleted: Int = 0
    var averageScore: Double = 100.0
    var daysTracked: Int = 0
}

func testBaseline(stats: [DayStats]) -> AggregatedStats {
    var result = AggregatedStats()
    for day in stats {
        result.breaksCompleted += day.breaksCompleted
        result.breaksSkipped += day.breaksSkipped
        result.totalBreakMinutes += day.totalBreakMinutes
        result.shortBreaksCompleted += day.shortBreaksCompleted
        result.longBreaksCompleted += day.longBreaksCompleted
    }
    result.daysTracked = stats.count
    result.averageScore = stats.reduce(0.0) { $0 + $1.dailyScore } / Double(stats.count)
    return result
}

func testOptimized(stats: [DayStats]) -> AggregatedStats {
    var result = AggregatedStats()
    var totalScore = 0.0
    for day in stats {
        result.breaksCompleted += day.breaksCompleted
        result.breaksSkipped += day.breaksSkipped
        result.totalBreakMinutes += day.totalBreakMinutes
        result.shortBreaksCompleted += day.shortBreaksCompleted
        result.longBreaksCompleted += day.longBreaksCompleted
        totalScore += day.dailyScore
    }
    result.daysTracked = stats.count
    result.averageScore = totalScore / Double(stats.count)
    return result
}

let stats = (0..<1_000_000).map { _ in DayStats() }

let start1 = Date()
for _ in 0..<10 {
    _ = testBaseline(stats: stats)
}
let duration1 = Date().timeIntervalSince(start1)
print("Baseline: \(duration1) seconds")

let start2 = Date()
for _ in 0..<10 {
    _ = testOptimized(stats: stats)
}
let duration2 = Date().timeIntervalSince(start2)
print("Optimized: \(duration2) seconds")
print("Improvement: \( (duration1 - duration2) / duration1 * 100 )%")
