## 2024-10-24 - Cached DateFormatters to improve performance
**Learning:** `DateFormatter` instantiations are extremely expensive and the application was instantiating them repeatedly in loops and rendering cycles.
**Action:** Always create a globally shared static instance or centralized manager for date formatters (like `Formatters.shared`) and reuse them across the application to save CPU cycles and memory.

## 2024-10-24 - Strict Concurrency Fixes on UI State
**Learning:** Fixing main actor isolation issues by indiscriminately applying `@MainActor` to simple static properties inside theme structs triggers cascading compiler errors across all non-isolated SwiftUI views and initializers referencing them. Similarly, dispatching back to the main actor via `Task { @MainActor in }` from inside an outer closure capturing `[weak self]` causes memory leaks if `self` is recaptured improperly as `[self]` inside the task.
**Action:** Annotate entire SwiftUI `View` structs with `@MainActor` if they depend on main actor-isolated properties (like themes), rather than attempting to isolate the caller functions internally. For internal `Task { @MainActor in }` inside closures, safely unwrap `self` before the task (`guard let self = self else { return }`) and capture it strongly inside the task list (`Task { @MainActor [self] in }`).
