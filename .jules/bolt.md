## 2024-06-25 - Avoid ISO8601DateFormatter instances in map/loops
**Learning:** Instantiating `ISO8601DateFormatter` is very expensive computationally. `AdherenceManager.exportAsJSON` and `RuntimeProfiler.getAnonymizedTelemetry` are doing it inside `map` operations over arrays.
**Action:** Always instantiate `ISO8601DateFormatter` and `DateFormatter` once outside loops and `map` operations, and reuse the instance.
