## 2026-07-25 - Cached expensive visibility checks in Floating Window
**Learning:** Found a critical performance bottleneck specific to this codebase's architecture where `CGWindowListCopyWindowInfo` and `UserDefaults` were being called synchronously inside a 60fps `CVDisplayLink` loop in `FloatingCounterWindow`, leading to severe CPU usage.
**Action:** Throttle expensive API calls inside high-frequency display link or mouse tracking loops using `ProcessInfo.processInfo.systemUptime` caching.
