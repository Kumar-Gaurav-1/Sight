## 2026-07-10 - Cached DateFormatter in frequently called properties
**Learning:** Found an expensive DateFormatter initialization inside the `updateDerivedProperties` loop (which runs every second) in `MenuBarViewModel.swift`. Instantiating `DateFormatter` repeatedly causes unnecessary CPU overhead and memory churn.
**Action:** Always extract `DateFormatter` instances into `private static let` properties when they are used in frequently called update functions, especially UI loops and timer ticks.
## 2026-07-10 - CI strict concurrency fixes
**Learning:** Encountered CI failures due to Swift 5.10 strict concurrency checks. 'nonisolated(unsafe)' causes a parsing error if placed before 'public static var'. Crossing actor boundaries in closures requires extracting 'Sendable' values (like Int) from non-Sendable payloads (like Notification) beforehand.
**Action:** Order modifiers as 'public static nonisolated(unsafe) var'. Always extract necessary values from Notification payloads before entering '@MainActor' Task closures to prevent capture warnings.
