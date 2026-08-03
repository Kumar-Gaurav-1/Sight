## 2024-11-20 - Hoisting expensive object instantiations in Swift closures
**Learning:** Instantiating `DateFormatter` or `ISO8601DateFormatter` inside a `.map` closure or tight loop in Swift causes massive redundant allocations and CPU overhead because formatting objects are notoriously heavy.
**Action:** Always hoist formatting object instantiations (like `DateFormatter` or `NumberFormatter`) out of loops or mapping closures into a local variable before the loop when acting on collections.
