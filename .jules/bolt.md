## 2024-10-11 - Caching DateFormatters

**Learning:** DateFormatter and ISO8601DateFormatter initialization is computationally expensive, especially when used in loops or UI updates (like MenuBar updates and rendering charts).

**Action:** Created a `SharedFormatters` class to cache formatters correctly configured for date and time and substituted them around the codebase to prevent excessive reinitialization in hot code paths.
