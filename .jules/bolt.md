## 2024-10-18 - Globally cached DateFormatters for Performance
**Learning:** Instantiating `DateFormatter` or `ISO8601DateFormatter` frequently inside tight loops or computed properties (like in UI rendering logic and JSON serialization loops) in Swift is a known massive performance bottleneck.
**Action:** Created a `SharedFormatters` singleton (`@unchecked Sendable`) configured with common date formats to replace localized instantiation instances throughout the codebase, significantly reducing CPU cycles and memory allocations when formatting dates.
