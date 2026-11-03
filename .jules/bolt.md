
## 2024-05-18 - Caching DateFormatters

**Learning:** DateFormatter instantiation is expensive. Profiling shows that instantiating a new DateFormatter inside loops or frequently called rendering functions adds significant overhead. Additionally, when extracting a `DateFormatter` into a shared instance, ensure `timeZone` and `locale` are set correctly (e.g. `.autoupdatingCurrent`) except for `ISO8601DateFormatter`, which must remain in GMT to allow for proper downstream syncing/sorting. Lastly, do NOT duplicate shared formatter wrappers into every file as `fileprivate`, use a centralized `Utils` class instead to truly share the instance across the codebase.
**Action:** When caching `DateFormatter` instances across multiple files, create a globally shared utility class (like `Formatters` in a `Utils` directory). Explicitly set properties like `.timeStyle` and `.timeZone` per formatter on initialization and re-use the instances.
