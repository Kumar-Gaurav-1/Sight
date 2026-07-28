
## 2024-05-24 - Expensive APIs in High-Frequency Event Handlers
**Learning:** `CGWindowListCopyWindowInfo` and `UserDefaults` were being called synchronously inside `handleMouseMoved` (NSEvent monitor) which fires on every cursor movement, causing severe CPU spikes and UI jank.
**Action:** Always throttle or cache expensive system calls (like `CGWindowListCopyWindowInfo` or `UserDefaults`) when used inside high-frequency event loops like `NSEvent` monitors or `CVDisplayLink` callbacks, maintaining separate state for cached expensive results.
