## 2024-09-18 - Cache DateFormatter in tight timer loops
**Learning:** In Swift, `DateFormatter` is very expensive to initialize. I found it being instantiated inside `updateDerivedProperties()`, which is called every second by a timer. This causes unnecessary continuous memory allocation and main thread overhead.
**Action:** Always statically cache `DateFormatter` when used in frequently executed contexts like timers or loops. Use `@unchecked Sendable` wrapper singletons to satisfy Swift 6 strict concurrency when caching these formatters safely.
