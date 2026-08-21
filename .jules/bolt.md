## 2026-08-21 - Caching JSONEncoder/Decoder for IPC performance
**Learning:** In Swift, JSONEncoder and JSONDecoder are thread-safe for concurrent calls once initialized, provided their configurations aren't mutated. Creating new instances for high-frequency operations like IPC (which sends updates every second) causes unnecessary allocation overhead.
**Action:** Statically cache JSONEncoder and JSONDecoder as private let properties for high-frequency encoding/decoding operations instead of instantiating them inline.
