## 2024-10-24 - Cached DateFormatters to improve performance
**Learning:** `DateFormatter` instantiations are extremely expensive and the application was instantiating them repeatedly in loops and rendering cycles.
**Action:** Always create a globally shared static instance or centralized manager for date formatters (like `Formatters.shared`) and reuse them across the application to save CPU cycles and memory.
