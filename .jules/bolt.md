## 2025-02-12 - DateFormatter Performance in map closures
**Learning:** Found multiple instances where `DateFormatter()` and `ISO8601DateFormatter()` are being instantiated inside `.map` closures or loops (e.g., `AdherenceManager.exportAsJSON` and `RuntimeProfiler.getAnonymizedTelemetry`). DateFormatter instantiation is notoriously expensive in Swift/Foundation.
**Action:** Extract DateFormatter instantiations outside of loops and mapping closures to reuse a single instance, preventing O(n) instantiations.
