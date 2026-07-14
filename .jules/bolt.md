## 2024-05-24 - Avoid DateFormatter in High-Frequency Loops
**Learning:** Instantiating `DateFormatter` inside a timer loop (like `MenuBarViewModel.updateDerivedProperties` which is called every second) is a significant performance bottleneck due to its heavy initialization cost and strict concurrency rules in Swift 5.10+.
**Action:** Use modern `FormatStyle` API (e.g., `date.formatted(date: .omitted, time: .shortened)`) which is highly optimized, thread-safe, and avoids caching issues with TimeZone/Locale changes.
