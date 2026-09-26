## 2023-10-26 - Cached DateFormatter globally
**Learning:** Found multiple instances of `DateFormatter` and `ISO8601DateFormatter` being initialized inside loops and frequently called methods like `exportAsJSON` and UI render cycles. This is computationally expensive and causes redundant memory allocations.
**Action:** Implemented a thread-safe, globally shared `FormatterCache` utilizing `@unchecked Sendable` to provide pre-configured formatters. Avoided mutating formatters prior to usage to ensure thread safety across contexts.
