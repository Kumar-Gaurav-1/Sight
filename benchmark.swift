import Foundation

struct FloatingCounterParams: Codable {
    var a: Int
    var b: String
}

let params = FloatingCounterParams(a: 1, b: "test")

func benchmark1() {
    let start = Date()
    for _ in 0..<100_000 {
        _ = try? JSONEncoder().encode(params)
    }
    print("New JSONEncoder: \(Date().timeIntervalSince(start))")
}

let encoder = JSONEncoder()
func benchmark2() {
    let start = Date()
    for _ in 0..<100_000 {
        _ = try? encoder.encode(params)
    }
    print("Cached JSONEncoder: \(Date().timeIntervalSince(start))")
}

benchmark1()
benchmark2()
