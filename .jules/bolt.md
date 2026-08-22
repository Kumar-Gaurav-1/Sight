## 2026-08-22 - DateFormatter Performance in Timer Loops
**Learning:** Instantiating `DateFormatter` inside a high-frequency timer loop (like `MenuBarViewModel`'s update method that runs every second) is computationally expensive and causes unnecessary CPU overhead.
**Action:** Cache `DateFormatter` as a static property instead of creating it inline. Use `#if compiler(>=5.10)` and `nonisolated(unsafe)` to ensure safe concurrent access and avoid strict concurrency warnings.
