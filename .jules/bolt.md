## 2026-02-20 - Cache ISO8601DateFormatter outside loops
**Learning:** Instantiating `ISO8601DateFormatter` is computationally expensive. Doing so inside a `map` closure or loop creates N unnecessary allocations, degrading performance.
**Action:** Extract the instantiation of `ISO8601DateFormatter` (and `DateFormatter`) outside of loops or closures to reuse a single instance, significantly reducing CPU time and memory allocations.
