## 2024-05-13 - DateFormatter Allocations in rendering loops
**Learning:** Instantiating `DateFormatter` in SwiftUI components (e.g. ActivityHeatmapView) or looping constructs (e.g. AdherenceManager export loops) without caching leads to performance bottlenecks due to the heavy cost of DateFormatter creation.
**Action:** Extract reusable formats into a single, global cache to prevent excessive DateFormatter reallocations.
