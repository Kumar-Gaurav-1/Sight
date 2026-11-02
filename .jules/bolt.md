## 2024-06-12 - Caching DateFormatter instances
**Learning:** `DateFormatter` and `ISO8601DateFormatter` are expensive to initialize and are used heavily in loops and UI components across the codebase.
**Action:** Create a global cache for specific formatters and replace local initializations to improve performance.
