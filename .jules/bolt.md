## 2024-07-07 - DateFormatter Instantiation in Timer Ticks
**Learning:** In this SwiftUI/Combine architecture, properties bound to the TimerStateMachine tick every second. Instantiating `DateFormatter` inside `updateDerivedProperties` causes continuous expensive allocations.
**Action:** Always extract `DateFormatter` and `ISO8601DateFormatter` to static properties, especially in view models responding to state machine ticks.
