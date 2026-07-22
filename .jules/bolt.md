
## 2024-05-27 - O(N^2) String Concatenation in Swift CSV Generation
**Learning:** Found instances of building CSV strings using `csv += "..."` inside loops in `AdherenceManager.swift`. While this might seem harmless for small datasets, Swift's string concatenation inside a loop can lead to O(N^2) time complexity due to repeated memory reallocation as the string grows.
**Action:** Always prefer collecting string parts into an array (e.g., using `map` over the dataset) and calling `.joined(separator:)` at the end to assemble the final string. This approach ensures amortized O(N) performance and cleaner, more declarative code.
