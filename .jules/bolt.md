## 2024-07-16 - ISO8601FormatStyle TimeZone Defaults
**Learning:** `DateFormatter` defaults to the local system time zone, while `Date.ISO8601FormatStyle` (via `.iso8601`) defaults to GMT/UTC. When replacing `DateFormatter` with `FormatStyle` to format dates (e.g., for CSV exports), failing to preserve the local time zone can introduce subtle bugs where events are attributed to the wrong day depending on the user's local time and time of day.
**Action:** Always append `.timeZone(.current)` when migrating local-time dependent `DateFormatter` usages to `ISO8601FormatStyle`.
