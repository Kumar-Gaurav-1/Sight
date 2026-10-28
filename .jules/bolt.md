## 2024-10-28 - DateFormatter Optimization
**Learning:** `DateFormatter` instantiation is expensive and doing it inline inside tight loops (`AdherenceManager.exportToCSV`, `InteractiveCharts.hourLabel`) or inside SwiftUI view rendering functions causes significant performance bottlenecks. Furthermore, directly altering `.timeStyle` or setting explicit format strings like `"h a"` on local instances ignores localization and caching.
**Action:** Always refactor local `DateFormatter` instantiations into a global thread-safe singleton cache (`SharedFormatters: @unchecked Sendable`). Configure `DateFormatter` properties (e.g., `locale = .autoupdatingCurrent`, `timeZone = .autoupdatingCurrent`) during init to allow them to adapt to system changes without needing to be re-instantiated.

## 2024-10-28 - Strict Concurrency in Custom Styles
**Learning:** In Swift 6 strict concurrency, do not annotate custom SwiftUI style structs (like `ButtonStyle` or `ToggleStyle`) with `@MainActor`. The `makeBody(configuration:)` protocol requirement is nonisolated, so isolating the struct or method to the main actor will result in a 'cannot be used to satisfy nonisolated protocol requirement' compiler error.
**Action:** To access `@MainActor`-isolated state within these styles (like `SightTheme.accent`), extract the view logic into a separate custom `View` struct (e.g., `SightPrimaryButtonView`) whose `body` is implicitly evaluated on the MainActor, and instantiate it inside `makeBody`.

## 2024-10-28 - Swift 5.10 vs Older Compiler Syntax Errors
**Learning:** In Swift environments where `nonisolated(unsafe)` causes syntax errors (e.g., yielding 'expected var keyword in property declaration'), the compiler version is older than Swift 5.10.
**Action:** Wrap the declaration in `#if compiler(>=5.10)` blocks with an `#else` fallback matching the original declaration (e.g., standard `public static var`). Do not arbitrarily change a `var` to a `let` to fix the syntax error, as this breaks initialization patterns.

## 2024-10-28 - Implicit @MainActor vs Strict Concurrency
**Learning:** If standard SwiftUI views trigger "main actor-isolated static property can not be referenced from a non-isolated context" for things like `SightTheme.accent`, explicitly annotate the entire `View` struct with `@MainActor`.
**Action:** When fixing actor isolation errors in a SwiftUI file containing multiple view structs, ensure `@MainActor` is applied to all relevant view structs within the file (e.g., helper subviews like `ScoreGaugeView`, `TrendSparklineView`), not just the primary view.

## 2024-10-28 - NotificationCenter Observers in Swift 6
**Learning:** In Swift 6 strict concurrency, `Foundation.Notification` does not conform to the `Sendable` protocol. Capturing it in a `@Sendable` closure (`NotificationCenter.default.addObserver`) paired with an internal `Task` causes errors.
**Action:** Ensure non-sendable types are processed synchronously outside the Task, passing only the extracted, sendable values (e.g., primitive integers like `minutes`) into the concurrent context.
