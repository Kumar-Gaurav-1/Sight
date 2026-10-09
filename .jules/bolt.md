## 2024-05-18 - Caching DateFormatters in Swift
**Learning:** `DateFormatter` and `ISO8601DateFormatter` are computationally expensive to instantiate. Repeated instantiation inside loops, frequently called functions, or SwiftUI views can cause significant performance overhead.
**Action:** Always extract `DateFormatter` instances into a globally shared singleton (e.g., `@unchecked Sendable` final class) and reuse them instead of creating new instances repeatedly.
