## 2024-03-24 - DateFormatter Caching
**Learning:** Caching computationally expensive objects like DateFormatter across multiple files using a globally shared utility class (e.g., `Formatters`) reduces CPU overhead and memory allocations significantly. Setting `.timeZone` and `.locale` to `.autoupdatingCurrent` preserves localization dynamics.
**Action:** Always extract local DateFormatter instantiations into a centralized thread-safe cache (`@unchecked Sendable` initialized with `let`).
