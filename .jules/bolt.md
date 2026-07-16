## 2024-05-24 - Use FormatStyle for ISO8601 Date Formatting
**Learning:** Instantiating `ISO8601DateFormatter` in a loop in Swift is expensive and creates unnecessary memory allocations and CPU overhead.
**Action:** Always prefer the `FormatStyle` API (e.g., `date.formatted(.iso8601)`) which is highly optimized, modern, and does not incur the object creation penalty of `DateFormatter` when serializing/formatting dates, especially in loops.
