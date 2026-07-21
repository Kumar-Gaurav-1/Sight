## 2024-05-15 - Prevent O(N) DateFormatter initialization and O(N^2) string concatenation
**Learning:** Instantiating `ISO8601DateFormatter()` inside a `map` loop (e.g., during telemetry export with thousands of events) and using `+=` string concatenation inside export loops are subtle performance bottlenecks in Swift that degrade performance significantly as data scales.
**Action:** Extract DateFormatter initializations outside of loops and use Array `.map` combined with `.joined(separator:)` to serialize data without repeated memory reallocations.
