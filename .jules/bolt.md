## 2024-05-14 - Replace DateFormatter with FormatStyle
**Learning:** Instantiating `DateFormatter` is very slow in Swift and causes performance issues, especially when created inside loops, computed properties, or frequently updating functions (like `MenuBarViewModel` timer updates). Caching as `static let` triggers Swift 6 concurrency warnings.
**Action:** Use modern, concurrency-safe `FormatStyle` APIs (e.g. `date.formatted()`) which are highly optimized and do not require instantiation overhead.
