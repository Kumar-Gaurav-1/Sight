## 2024-05-18 - Avoid DateFormatter in frequent UI updates
**Learning:** Initializing DateFormatter is computationally expensive in Swift. Doing so inside frequent update loops (like MenuBarViewModel.updateDerivedProperties()) causes unnecessary CPU spikes and memory allocations.
**Action:** Replace DateFormatter allocations with the highly optimized, concurrency-safe FormatStyle API (e.g., date.formatted(date: .omitted, time: .shortened)) in modern Swift (iOS 15+, macOS 12+).
