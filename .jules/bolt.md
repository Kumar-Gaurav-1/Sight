## 2025-02-20 - DateFormatter initialization inside loops / property getters
**Learning:** In Swift, DateFormatter initialization is computationally expensive. Found instances where it's initialized inside a getter property repeatedly or a loop, leading to performance bottlenecks.
**Action:** Initialize DateFormatter once statically or at class/struct scope and reuse it to improve performance.
