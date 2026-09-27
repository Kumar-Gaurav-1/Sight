## 2024-05-19 - Globally Cached DateFormatters
**Learning:** Instantiating `DateFormatter` or `ISO8601DateFormatter` frequently causes unnecessary allocations and compute cycles in Swift. `DateFormatter` object creation is expensive in Foundation.
**Action:** Centralize `DateFormatter` creations into a globally cached `SharedFormatters` object marked `@unchecked Sendable` using a conditional compiler block `#if compiler(>=5.10)` to satisfy Swift 6 strict concurrency checks without throwing syntax errors on older Swift compilers.
