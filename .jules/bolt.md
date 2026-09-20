## 2024-05-23 - DateFormatter caching across components
**Learning:** Caching computationally expensive `DateFormatter` instances as static `fileprivate` singletons prevents memory re-allocations in frequently called views and engines.
**Action:** When globally caching `DateFormatter` or `ISO8601DateFormatter` instances in Swift 6, to avoid strict concurrency isolation errors while maintaining performance, wrap them inside a `fileprivate final class SharedFormatters: @unchecked Sendable` singleton.
