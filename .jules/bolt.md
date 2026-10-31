## 2024-10-31 - Cache DateFormatter instances in loops
**Learning:** Initializing `DateFormatter` or `ISO8601DateFormatter` is notoriously expensive in Swift. Doing this repeatedly, particularly in loops or frequently called rendering code (like `MenuBarViewModel` updating the ETA), is a common performance bottleneck.
**Action:** Always create a shared instance or cached formatter for recurring date formatting tasks, rather than instantiating a new formatter inline. Make sure it sets the timezone and locale explicitly if using it across contexts.
