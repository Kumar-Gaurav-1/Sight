## 2026-07-10 - Cached DateFormatter in frequently called properties
**Learning:** Found an expensive DateFormatter initialization inside the `updateDerivedProperties` loop (which runs every second) in `MenuBarViewModel.swift`. Instantiating `DateFormatter` repeatedly causes unnecessary CPU overhead and memory churn.
**Action:** Always extract `DateFormatter` instances into `private static let` properties when they are used in frequently called update functions, especially UI loops and timer ticks.
