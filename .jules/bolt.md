## 2026-08-23 - Cache JSONEncoder and JSONDecoder in IPC
**Learning:** Instantiating JSONEncoder and JSONDecoder is computationally expensive and they are thread-safe for concurrent encode() and decode() calls. In high-frequency operations like IPC, caching them improves performance significantly.
**Action:** Cache JSONEncoder and JSONDecoder as private let properties rather than recreating them inside loops or frequent IPC callbacks.
