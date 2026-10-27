## 2024-10-27 - Initial Journal Entry
**Learning:** Found multiple instances of `DateFormatter` being created repeatedly in loops, computed properties, and formatting functions across the app (SightBreaksView, InteractiveCharts, SightStatisticsView, AdherenceManager, InsightsEngine, RuntimeProfiler, MenuBarViewModel). `DateFormatter` is notoriously expensive to instantiate in Swift.
**Action:** Consolidate these into a shared global formatter cache (e.g. `SharedFormatters` or similar utility) to avoid performance overhead from repeated allocations.
