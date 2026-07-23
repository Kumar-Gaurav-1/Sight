## 2024-07-23 - Throttling expensive UI checks on mouse movement
**Learning:** `CGWindowListCopyWindowInfo` and `UserDefaults` checks were being called in `handleMouseMoved` at 60Hz+. This causes severe CPU spikes during normal cursor movement.
**Action:** Throttle expensive state queries (fullscreen check, UserDefaults read) that don't need real-time precision when checking visibility on every frame.
