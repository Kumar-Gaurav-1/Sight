## 2024-05-23 - DateFormatter caching

**Learning:** Reusing DateFormatters by caching them globally instead of creating them on the fly can result in a massive performance improvement since DateFormatter initialization is notoriously expensive in Swift.

**Action:** Whenever multiple classes and views use DateFormatters or ISO8601DateFormatter, check if they can be cached in a global, thread-safe, `@unchecked Sendable` singleton.
## 2026-10-15 - Unrelated concurrency fixes

**Learning:** When acting as the Bolt persona to implement a targeted performance optimization (under 50 lines), avoid massive, unrelated refactoring to silence pre-existing Swift strict concurrency warnings. If your out-of-scope concurrency fixes cause cascading compiler errors (e.g., UI protocol conformance issues), revert the bloated changes and scope your submission strictly to the original optimization.

**Action:** Revert changes that cause unrelated compilation failures, such as indiscriminately applying `@MainActor` to theme structs or changing singleton initialization logic.
