## 2026-08-24 - Cache ISO8601DateFormatter
**Learning:** Initializing ISO8601DateFormatter is notoriously slow in Swift. Calling it inside a loop or higher-order function scales O(N) in instantiation overhead compared to an O(1) single allocation.
**Action:** Always instantiate DateFormatter and ISO8601DateFormatter outside loops when iterating or mapping elements.
