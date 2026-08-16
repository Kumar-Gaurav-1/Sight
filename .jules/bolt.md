## 2024-08-16 - Cache JSONEncoder instances
**Learning:** Instantiating JSONEncoder repeatedly in high-frequency paths adds measurable overhead.
**Action:** Cache JSONEncoder instances as private properties to avoid unnecessary allocations.
