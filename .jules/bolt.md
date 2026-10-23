
## 2024-05-14 - Global DateFormatter Cache Optimization
**Learning:** Found widespread inline instantiation of `DateFormatter` and `ISO8601DateFormatter` across various views, data models, and loops. Instantiating date formatters is notoriously expensive in Swift. Creating a `@unchecked Sendable` singleton to cache these formatters optimizes performance by avoiding repeated initialization costs, specifically inside loops and during UI updates.
**Action:** Always extract and reuse computationally expensive foundational types like `DateFormatter` via a globally shared cache rather than inline instantiations, especially in SwiftUI views or data processing pipelines.
