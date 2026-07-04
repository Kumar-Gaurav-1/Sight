import Foundation

let path = "Sources/Sight/Preferences/SightAboutView.swift"
var content = try! String(contentsOfFile: path, encoding: .utf8)
content = content.replacingOccurrences(of: "private var appInfoCard: some View {", with: "@MainActor\n    private var appInfoCard: some View {")
content = content.replacingOccurrences(of: "private var featuresCard: some View {", with: "@MainActor\n    private var featuresCard: some View {")
try! content.write(toFile: path, atomically: true, encoding: .utf8)
print("Updated SightAboutView.swift")
