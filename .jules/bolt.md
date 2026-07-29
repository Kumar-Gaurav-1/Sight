## 2024-07-29 - Avoid synchronous expensive APIs in high-frequency event handlers
**Learning:** Calling expensive APIs like `CGWindowListCopyWindowInfo` synchronously inside high-frequency event handlers (like mouse tracking) causes CPU spikes.
**Action:** Throttle the calls to expensive APIs and cache the results when executing inside high-frequency event handlers. Allow cheap real-time checks to execute normally.
