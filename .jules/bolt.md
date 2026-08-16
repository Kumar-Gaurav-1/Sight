## 2024-08-16 - Cache JSONEncoder
**Learning:** JSONEncoder is frequently allocated in IPC routines which leads to unnecessary allocations and CPU overhead, especially when methods are called often.
**Action:** Always check if a JSONEncoder can be extracted into a class property (e.g. `private let encoder = JSONEncoder()`) to share instances across encode/decode operations.
