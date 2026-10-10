## 2026-10-10 - DateFormatter Instances Everywhere
**Learning:** Found multiple instances of `DateFormatter` and `ISO8601DateFormatter` being repeatedly initialized inside functions and views (e.g., `SightStatisticsView.swift`, `AdherenceManager.swift`, `PreferencesManager.swift`, `InteractiveCharts.swift`, `SightBreaksView.swift`). `DateFormatter` initialization is known to be computationally expensive in Swift/Foundation.
**Action:** Create a global singleton cache for date formatters to avoid re-instantiation overhead and apply it across the codebase.
