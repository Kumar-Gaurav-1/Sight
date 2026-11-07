import Foundation

#if compiler(>=5.10)
public final class Formatters: @unchecked Sendable {
    public static let shared = Formatters()

    public let iso8601: ISO8601DateFormatter

    private init() {
        self.iso8601 = ISO8601DateFormatter()
    }
}
#else
public final class Formatters {
    public static let shared = Formatters()

    public let iso8601: ISO8601DateFormatter

    private init() {
        self.iso8601 = ISO8601DateFormatter()
    }
}
#endif
