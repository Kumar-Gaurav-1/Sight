import Foundation

/// A globally shared cache for DateFormatter and ISO8601DateFormatter instances.
/// This prevents the computationally expensive initialization of these formatters
/// inside loops, computed properties, or frequently called methods, which can
/// cause measurable performance degradation.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    /// Formatter for "yyyy-MM-dd"
    public let yyyyMMdd: DateFormatter

    /// Formatter for "EEEE" (e.g., Monday, Tuesday)
    public let eeee: DateFormatter

    /// Formatter for "EEE" (e.g., Mon, Tue)
    public let eee: DateFormatter

    /// ISO8601 Formatter
    public let iso8601: ISO8601DateFormatter

    /// Formatter for "h a" (e.g., 5 PM)
    public let ha: DateFormatter

    /// Formatter for timeStyle = .short (respects user 12/24h preference)
    public let shortTime: DateFormatter

    private init() {
        let f1 = DateFormatter()
        f1.dateFormat = "yyyy-MM-dd"
        f1.locale = .autoupdatingCurrent
        f1.timeZone = .autoupdatingCurrent
        self.yyyyMMdd = f1

        let f2 = DateFormatter()
        f2.dateFormat = "EEEE"
        f2.locale = .autoupdatingCurrent
        f2.timeZone = .autoupdatingCurrent
        self.eeee = f2

        let f3 = DateFormatter()
        f3.dateFormat = "EEE"
        f3.locale = .autoupdatingCurrent
        f3.timeZone = .autoupdatingCurrent
        self.eee = f3

        self.iso8601 = ISO8601DateFormatter()

        let f5 = DateFormatter()
        f5.dateFormat = "h a"
        f5.locale = .autoupdatingCurrent
        f5.timeZone = .autoupdatingCurrent
        self.ha = f5

        let f6 = DateFormatter()
        f6.timeStyle = .short
        f6.locale = .autoupdatingCurrent
        f6.timeZone = .autoupdatingCurrent
        self.shortTime = f6
    }
}
