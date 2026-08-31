1. **Analyze the DateFormatter Performance Bottleneck**
   - Instantiating `DateFormatter` and `ISO8601DateFormatter` frequently or in tight loops (e.g., UI rendering or export functions) is a well-known performance bottleneck in Swift due to high allocation and initialization overhead.
   - The current codebase instantiates formatters repeatedly in several places:
     - `AdherenceManager`
     - `MenuBarViewModel`
     - `PreferencesManager`
     - `SightBreaksView`
     - `InteractiveCharts`
     - `SightStatisticsView`
     - `RuntimeProfiler`
     - `InsightsEngine`
     - `StatisticsEngine`

2. **Create a Centralized Formatters Cache**
   - Use `run_in_bash_session` to create `Sources/Sight/Core/Formatters.swift` providing statically cached, thread-safe instances of `DateFormatter` and `ISO8601DateFormatter` (like `shortTimeFormatter`, `dayFormatter`, `dateFormatter`, `iso8601Formatter`, `hourFormatter`, `shortDayFormatter`).
   - Use `#if compiler(>=5.10)` combined with `nonisolated(unsafe)` for strict concurrency safety, with a fallback for older compilers.

3. **Refactor Codebase to use Cached Formatters**
   - Use `run_in_bash_session` to run a Python script to search-and-replace all inline instantations of `DateFormatter` and `ISO8601DateFormatter` with their corresponding cached versions from `Formatters`.
   - Update usages to use `Formatters.iso8601Formatter`, `Formatters.shortTimeFormatter`, etc.

4. **Compile Code and Run Tests to Verify**
   - Use `run_in_bash_session` to execute Swift format or simply ensure everything parses successfully (since `swift test` may not be available on this sandbox we can verify with `git diff`).

5. **Complete pre-commit steps**
   - Complete pre commit steps to make sure proper testing, verifications, reviews and reflections are done.

6. **Submit PR**
   - Use the `submit` tool to create the PR with the title: `⚡ Bolt: Cache DateFormatter instances to improve performance` and the required description formatting.
