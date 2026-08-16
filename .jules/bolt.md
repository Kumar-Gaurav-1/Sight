## 2024-05-15 - Cache Foundation Encoders/Decoders
**Learning:** Instantiating JSONEncoder and JSONDecoder repeatedly in high-throughput paths (like IPC or rendering loops) causes unnecessary memory allocations and CPU overhead in Swift.
**Action:** Always cache these objects as instance or static properties when used repeatedly.
