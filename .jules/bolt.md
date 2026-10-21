## 2024-05-18 - Caching Swift DateFormatter Instances
**Learning:** Instantiating `DateFormatter` in Swift is notoriously expensive. Creating them inside loops or frequently called rendering methods (like those in UI components or data export functions) causes measurable performance bottlenecks and excessive memory allocations.
**Action:** Always create a central, thread-safe (e.g., using `@unchecked Sendable` or global actors) cache of statically configured `DateFormatter` instances to reuse across the application.
