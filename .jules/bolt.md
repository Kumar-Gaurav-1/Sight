## 2024-08-01 - Global system idle time
**Learning:** Checking idle time by individual event types (mouseMoved, keyDown, etc.) requires multiple C-bridge calls.
**Action:** Use `CGEventType(rawValue: ~0)!` (kCGAnyInputEventType) to efficiently get global system idle time in a single CoreGraphics call.

## 2024-08-01 - Swift Enum Initialization and kCGAnyInputEventType
**Learning:** Initializing `CGEventType(rawValue: ~0)!` crashes at runtime in Swift because `~0` (`UInt32.max`) is not a valid predefined case in the `CGEventType` strict enum.
**Action:** Use `unsafeBitCast(UInt32.max, to: CGEventType.self)` to safely bridge the `kCGAnyInputEventType` macro from C to Swift without runtime crashes.
