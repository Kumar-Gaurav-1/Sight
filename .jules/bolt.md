## 2024-08-10 - Expensive DateFormatters in Loops
**Learning:** Found multiple instances where ISO8601DateFormatter was being instantiated inside `.map` closures (AdherenceManager, RuntimeProfiler), causing O(N) expensive allocations.
**Action:** Always instantiate DateFormatter and ISO8601DateFormatter instances outside of loops and map operations to prevent redundant overhead.
