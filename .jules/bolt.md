## 2024-05-30 - DateFormatter initialization inside loops
**Learning:** `DateFormatter` and `ISO8601DateFormatter` initialization is expensive. When initialized repeatedly in functions that are called frequently or inside loops, it can introduce significant performance bottlenecks.
**Action:** Extract formatters to shared, cached instances. E.g., wrap in a `final class SharedFormatters: @unchecked Sendable` singleton to maintain thread safety while avoiding multiple costly initializations.
