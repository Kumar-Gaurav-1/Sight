
## 2024-05-24 - Globablly cached DateFormatter instances
**Learning:** Instantiating DateFormatter is computationally expensive in Swift and causes redundant memory allocations when called frequently or in tight loops. Caching it globally as a statically cached property improves performance.
**Action:** Extract formatters to a globally shared utility class when used across the codebase.
