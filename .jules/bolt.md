## 2024-05-30 - DateFormatter in High-Frequency UI Updates
**Learning:** Instantiating `DateFormatter` inline within 1-second refresh cycles (like `MenuBarViewModel` state machine ticks) creates unnecessary main thread allocations and overhead in Swift applications, significantly impacting CPU/Energy over long active sessions.
**Action:** Always use a `private static let` initialized formatter or explicitly cache the formatter for any high-frequency, repeated string formatting on the Main actor.
