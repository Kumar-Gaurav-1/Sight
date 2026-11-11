## 2024-05-12 - DateFormatter Performance Impact
**Learning:** Instantiating `DateFormatter` repeatedly in SwiftUI views and tight loops creates a measurable overhead due to its expensive initialization and locale/timezone resolution.
**Action:** Create a centralized `SharedFormatters` class that caches all necessary `DateFormatter` instances with `.autoupdatingCurrent` configurations.
