## 2024-06-12 - Cached DateFormatter in Timer Updates
**Learning:** `DateFormatter` is a known expensive object in Swift/Foundation. The `MenuBarViewModel` handles timer ticks (typically every second), and creating a new `DateFormatter` inside `updateDerivedProperties()` on every tick caused unnecessary CPU overhead and memory allocations.
**Action:** Always extract and cache expensive objects like `DateFormatter` or `JSONEncoder`/`JSONDecoder` as properties (or static properties) rather than creating them repeatedly inside frequent execution loops, such as timer update functions.
