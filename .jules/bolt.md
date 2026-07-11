## 2026-07-11 - DateFormatter Bottleneck inside Update Loops
**Learning:** Found an anti-pattern in MenuBarViewModel where `DateFormatter` is instantiated repeatedly within a highly accessed timer state machine's derived properties updates (`updateDerivedProperties()`). Instantiating `DateFormatter` is notoriously expensive in Swift and impacts CPU when done within loops, timer-based callbacks, or UI updates.
**Action:** Extract `DateFormatter` to static properties to ensure it's initialized only once, reducing CPU overhead during continuous updates.
