## 2024-05-15 - Expensive Formatter Initialization in Map Closure
**Learning:** Instantiating DateFormatter or ISO8601DateFormatter inside a .map() closure (like in getAnonymizedTelemetry or exportAsJSON) is computationally expensive, especially for large collections.
**Action:** Always extract the formatter instantiation outside the .map() closure to reuse the same instance, significantly reducing processing time and memory allocations.
