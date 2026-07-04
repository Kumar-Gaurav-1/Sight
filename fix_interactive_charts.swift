import Foundation

let path = "Sources/Sight/Preferences/InteractiveCharts.swift"
var content = try! String(contentsOfFile: path, encoding: .utf8)
content = content.replacingOccurrences(of: "private var scoreColor: Color {", with: "@MainActor\n    private var scoreColor: Color {")
content = content.replacingOccurrences(of: "private var scoreGradient: AngularGradient {", with: "@MainActor\n    private var scoreGradient: AngularGradient {")
content = content.replacingOccurrences(of: "private func color(for reason: String) -> Color {", with: "@MainActor\n    private func color(for reason: String) -> Color {")
try! content.write(toFile: path, atomically: true, encoding: .utf8)
print("Updated InteractiveCharts.swift")
