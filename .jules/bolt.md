## 2026-09-24 - DateFormatter/ISO8601DateFormatter memory allocations
**Learning:** Instantiating DateFormatter or ISO8601DateFormatter in loops or frequently called methods is computationally expensive and causes redundant memory allocations. Caching these formatters globally improves performance significantly.
**Action:** Always create a globally shared, static, cached instance of formatters instead of instantiating them on-demand, especially in loops.
