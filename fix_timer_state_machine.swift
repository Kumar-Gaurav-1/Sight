import Foundation

let path = "Sources/Sight/Core/TimerStateMachine.swift"
var content = try! String(contentsOfFile: path, encoding: .utf8)
content = content.replacingOccurrences(of: "nonisolated(unsafe) public static let shared: TimerStateMachine = TimerStateMachine(configuration: .default)", with: "@MainActor\n    nonisolated(unsafe) public static let shared: TimerStateMachine = TimerStateMachine(configuration: .default)")
try! content.write(toFile: path, atomically: true, encoding: .utf8)
print("Updated TimerStateMachine.swift")
