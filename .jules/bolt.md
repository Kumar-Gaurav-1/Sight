## 2024-11-04 - Caching DateFormatter instances
**Learning:** Creating `DateFormatter` and `ISO8601DateFormatter` instances inside loops, closures, or computed properties is a known performance bottleneck in Swift due to their heavy initialization cost.
**Action:** Create a centralized, shared cache for `DateFormatter` instances, and use them throughout the app to avoid recreating them.
