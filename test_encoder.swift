import Foundation

class XPCRendererClient {
    private static let encoder = JSONEncoder()

    func test() {
        _ = try? Self.encoder.encode("test")
    }
}
