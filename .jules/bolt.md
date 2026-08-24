## 2026-08-24 - Cache DateFormatter instances in loops
**Learning:** In Swift, initializing `ISO8601DateFormatter` inside a loop is computationally expensive. However, `ISO8601DateFormatter` is thread-safe for formatting strings and can safely be cached.
**Action:** Statically cache `ISO8601DateFormatter` (using `nonisolated(unsafe)` for strict concurrency compatibility) rather than instantiating it per loop iteration to improve performance.
