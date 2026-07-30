## 2024-07-30 - Expensive API Call in Render Loop
**Learning:** Calling `CGWindowListCopyWindowInfo` on every frame update (`updatePhysics()` via CVDisplayLink -> `shouldAutoHide()` -> `isInFullscreenApp()`) causes extreme CPU usage and UI jank because it's a very expensive synchronous API call being made ~60 times a second.
**Action:** Always cache or throttle expensive API calls (like checking for fullscreen apps) when they are invoked within a high-frequency render loop (like `CVDisplayLink` or `CADisplayLink`).
