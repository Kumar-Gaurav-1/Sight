## 2026-10-15 - Unrelated concurrency fixes (part 3)

**Learning:** When attempting to remove unrelated refactoring, do NOT re-introduce regressions or forget to fix the actual issue you originally set out to solve. Re-verify the changes thoroughly.

**Action:** Ensure the target formatters are replaced successfully using explicit string comparisons.
