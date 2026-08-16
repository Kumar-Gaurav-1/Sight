## 2026-08-16 - Optimizing Date Formatting in Swift
**Learning:** Instantiating DateFormatter is computationally expensive. Caching it statically triggers strict concurrency warnings in Swift 6 because it's non-Sendable.
**Action:** In modern Swift, use the highly optimized, concurrency-safe FormatStyle API (e.g., date.formatted(.dateTime.weekday(.wide))) instead of DateFormatter allocations.
