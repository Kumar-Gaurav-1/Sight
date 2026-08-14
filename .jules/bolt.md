## 2025-02-20 - DateFormatter initialization inside loops / property getters
**Learning:** In Swift, DateFormatter initialization is computationally expensive. Found instances where it's initialized inside a getter property repeatedly or a loop, leading to performance bottlenecks.
**Action:** Initialize DateFormatter once statically or at class/struct scope and reuse it to improve performance.
## 2025-02-20 - DateFormatter vs FormatStyle
**Learning:** Statically caching DateFormatter is computationally faster but triggers strict concurrency warnings in Swift 6 as it is non-Sendable. Additionally, caching with .autoupdatingCurrent breaks localized testing.
**Action:** In modern Swift (iOS 15+, macOS 12+), avoid DateFormatter allocations entirely and use the highly optimized and concurrency-safe FormatStyle API (e.g., date.formatted(date: .omitted, time: .shortened)).
