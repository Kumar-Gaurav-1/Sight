## 2026-08-24 - Cache DateFormatter in loops
**Learning:** Instantiating DateFormatter (or ISO8601DateFormatter) inside a tight loop is highly inefficient. It's better to instantiate it once before the loop and reuse it.
**Action:** Always move DateFormatter instantiation outside of loops like map closures for significant performance gains.
