## 2024-10-19 - Cache DateFormatter instances across the codebase
**Learning:** Instantiating `DateFormatter` repeatedly in UI rendering loops or loops processing historical statistics is a well-known performance bottleneck, as formatting initialization is computationally expensive.
**Action:** Created a `Formatters` global singleton using `@unchecked Sendable` to safely cache and reuse instances with required formats, resolving repeated initializations in the `Sight` repository.
