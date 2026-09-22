
## 2024-05-18 - Globally cached formatters inside UI views

**Learning:** Instantiating `DateFormatter` is very computationally expensive and allocating them within loops or `@ViewBuilder` methods (like `.string(from:)` within charts or statistics views) is a hidden performance trap, especially for an app aiming for negligible battery impact on macOS. Sharing them across components effectively minimizes overhead.
**Action:** Always create a centralized struct or enum (e.g. `SharedFormatters`) using thread-safe caching to reuse `DateFormatter` across all views, but use `#if compiler(>=5.10)` blocks wrapping `nonisolated(unsafe)` (or just directly define them) to ensure we satisfy Swift strict concurrency rules.
