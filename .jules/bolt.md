
## 2024-11-07 - ISO8601DateFormatter TimeZone Behavior
**Learning:** `ISO8601DateFormatter` requires specific handling when globally caching. Unlike regular `DateFormatter`, we DO NOT set `.timeZone = .autoupdatingCurrent`. It must retain its default GMT (Z) timezone, as local timezone offsets break lexicographical sorting of dates and cause downstream issues in data synchronization and timestamp comparisons.
**Action:** When caching `DateFormatter` across a codebase, ensure that `ISO8601DateFormatter` is initialized with default settings and explicitly avoid applying autoupdating timezone properties.
