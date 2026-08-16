## 2024-05-19 - Cache JSONEncoder
**Learning:** In modern Swift, `JSONEncoder` instances are thread-safe for concurrent `encode()` calls. Repeatedly instantiating them in high-frequency paths like IPC adds unnecessary overhead.
**Action:** Cache `JSONEncoder` and `JSONDecoder` instances as `private let` properties for performance optimizations in loops or high-frequency methods.
