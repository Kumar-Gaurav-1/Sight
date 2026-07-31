## 2024-07-31 - DateFormatter Instantiation inside Maps
**Learning:** Instantiating `ISO8601DateFormatter` (or `DateFormatter`) is computationally expensive in Swift. Creating a new instance inside a loop or `.map` closure (e.g., when serializing arrays of telemetry events or daily stats) causes redundant allocations and CPU overhead, significantly impacting performance on large datasets.
**Action:** Always instantiate a single `(ISO8601)DateFormatter` instance outside the loop/map and reuse it across iterations when serializing or formatting collections of dates.
