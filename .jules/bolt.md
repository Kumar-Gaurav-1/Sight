
## 2024-05-18 - Caching DateFormatters for Performance
**Learning:** `DateFormatter` and `ISO8601DateFormatter` are expensive to initialize. I found multiple files initializing them repeatedly within properties and loops (e.g. 14 occurrences originally). This consumes memory and cpu unnecessarily. I consolidated them into a globally shared utility class (`SharedFormatters`) and replaced all local initializations. The formatters are safe to use concurrently (`@unchecked Sendable`) as long as they are not mutated after initialization.
**Action:** Use a statically cached `SharedFormatters` class to provide commonly used date and time formatters across the application to reduce allocation overhead.
