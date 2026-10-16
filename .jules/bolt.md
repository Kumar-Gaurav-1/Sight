## 2024-05-23 - DateFormatter caching

**Learning:** Reusing DateFormatters by caching them globally instead of creating them on the fly can result in a massive performance improvement since DateFormatter initialization is notoriously expensive in Swift.

**Action:** Whenever multiple classes and views use DateFormatters or ISO8601DateFormatter, check if they can be cached in a global, thread-safe, `@unchecked Sendable` singleton.
