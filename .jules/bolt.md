## 2026-07-10 - Cached DateFormatter in frequently called properties
**Learning:** Found an expensive DateFormatter initialization inside the `updateDerivedProperties` loop (which runs every second) in `MenuBarViewModel.swift`. Instantiating `DateFormatter` repeatedly causes unnecessary CPU overhead and memory churn.
**Action:** Always extract `DateFormatter` instances into `private static let` properties when they are used in frequently called update functions, especially UI loops and timer ticks.
## 2026-07-10 - CI strict concurrency fixes
**Learning:** Encountered CI failures due to Swift 5.10 strict concurrency checks. 'nonisolated(unsafe)' causes a parsing error if placed before 'public static var'. Crossing actor boundaries in closures requires extracting 'Sendable' values (like Int) from non-Sendable payloads (like Notification) beforehand.
**Action:** Order modifiers as 'public static nonisolated(unsafe) var'. Always extract necessary values from Notification payloads before entering '@MainActor' Task closures to prevent capture warnings.
## 2026-07-10 - CI strict concurrency fixes part 2
**Learning:** Found more Swift 5.10 strict concurrency CI failures: 1. MainActor isolated static properties like 'SightTheme.accent' cannot be referenced from non-isolated views or helper methods; SwiftUI views using them must be explicitly annotated with '@MainActor'. 2. To satisfy older compilers that do not support 'nonisolated(unsafe)' while preserving strict concurrency suppression for Swift 5.10+, conditional compilation directives '#if compiler(>=5.10)' must be used.
**Action:** When creating SwiftUI Views or helper methods referencing '@MainActor' properties, always annotate the struct/method with '@MainActor'. Use conditional compilation for newer concurrency keywords to maintain backward compatibility in CI pipelines.
## 2026-07-10 - CI strict concurrency fixes part 3
**Learning:** Found more Swift 5.10 strict concurrency CI failures: Custom UI styles like ButtonStyle and ToggleStyle cannot reference '@MainActor'-isolated static properties unless the styles themselves or their 'makeBody' methods are annotated with '@MainActor'.
**Action:** When creating SwiftUI ButtonStyle, ToggleStyle, or other ViewModifiers referencing '@MainActor' properties, always annotate the struct with '@MainActor' to satisfy strict concurrency.
