
## 2023-10-22 - Optimize DateFormatter Instantiations
**Learning:** Re-instantiating `DateFormatter` and `ISO8601DateFormatter` inside loops or frequent getters is a massive performance drain in Swift apps, as initialization is expensive and requires parsing system locale and timezone rules.
**Action:** Extract frequently used formatters to a globally shared `@unchecked Sendable` singleton, and reuse them across the application to save memory and CPU cycles during data exports and rendering.
