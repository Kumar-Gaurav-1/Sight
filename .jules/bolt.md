
## 2024-05-18 - Caching DateFormatters for Performance
**Learning:** `DateFormatter` and `ISO8601DateFormatter` are expensive to initialize. I found multiple files initializing them repeatedly within properties and loops (e.g. 14 occurrences originally). This consumes memory and cpu unnecessarily. I consolidated them into a globally shared utility class (`SharedFormatters`) and replaced all local initializations. The formatters are safe to use concurrently (`@unchecked Sendable`) as long as they are not mutated after initialization.
**Action:** Use a statically cached `SharedFormatters` class to provide commonly used date and time formatters across the application to reduce allocation overhead.

## 2024-05-18 - SwiftUI ButtonStyle Concurrency Fixes
**Learning:** In Swift 6 strict concurrency, do not annotate custom SwiftUI style structs (like `ButtonStyle` or `ToggleStyle`) with `@MainActor`. The `makeBody(configuration:)` protocol requirement is nonisolated, so isolating the struct or method to the main actor will result in a 'cannot be used to satisfy nonisolated protocol requirement' compiler error. To access `@MainActor`-isolated state within these styles, either remove the strict `@MainActor` requirement from the state if safe to do so, or extract the view logic into a separate custom `View` struct whose `body` is implicitly evaluated on the MainActor.
**Action:** Extract inner view logic to custom Views when dealing with protocol isolation mismatches in SwiftUI Styles.
