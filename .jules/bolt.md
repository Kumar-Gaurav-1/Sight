## 2025-01-24 - [Cache DateFormatter inside frequently invoked code]
**Learning:** `DateFormatter` initialization is notoriously expensive in Swift. Creating a new instance every single tick inside a timer loop (`updateDerivedProperties`) creates significant overhead in CPU and memory allocations, negatively impacting background app performance.
**Action:** Always cache `DateFormatter` (or `NumberFormatter`, `ISO8601DateFormatter`) as a static or lazy instance property rather than instantiating them within frequently executed code blocks.
