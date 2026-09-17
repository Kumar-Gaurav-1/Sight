## 2024-05-24 - Cache DateFormatters in Data Export Loops
**Learning:** Instantiating `DateFormatter` or `ISO8601DateFormatter` inside tight loops (like `.map` arrays during JSON/CSV data export) causes massive redundant allocations. While this is a generic Swift performance tip, it frequently occurs in this architecture's Manager classes (like AdherenceManager) when generating statistics objects.
**Action:** Always extract and locally cache formatters outside the loop when transforming large data collections synchronously.
