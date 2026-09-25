## 2024-05-14 - Global DateFormatter Caching in Swift
**Learning:** Instantiating `DateFormatter` or `ISO8601DateFormatter` frequently in Swift (especially in UI rendering loops or large dataset processing) is highly inefficient due to memory allocation and underlying C locale setup.
**Action:** Created a globally shared, `@unchecked Sendable` singleton class (`SharedFormatters`) to statically cache pre-configured formatters. Ensure that these are centralized in `Sources/Sight/Utils/Formatters.swift` to adhere to DRY principles and maintain Swift 6 strict concurrency compliance.
