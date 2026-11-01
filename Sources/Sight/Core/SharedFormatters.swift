import Foundation

/// Shared formatters for performance optimization.
/// Creating DateFormatters is expensive, so we cache them here.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter
    public let yyyyMMdd: DateFormatter
    public let eeee: DateFormatter
    public let shortTime: DateFormatter
    public let ha: DateFormatter
    public let eee: DateFormatter

    private init() {
        // ISO8601DateFormatter should maintain its default GMT (Z) timezone.
        self.iso8601 = ISO8601DateFormatter()

        let yyyyMMdd = DateFormatter()
        yyyyMMdd.dateFormat = "yyyy-MM-dd"
        yyyyMMdd.timeZone = .autoupdatingCurrent
        yyyyMMdd.locale = .autoupdatingCurrent
        self.yyyyMMdd = yyyyMMdd

        let eeee = DateFormatter()
        eeee.dateFormat = "EEEE"
        eeee.timeZone = .autoupdatingCurrent
        eeee.locale = .autoupdatingCurrent
        self.eeee = eeee

        let shortTime = DateFormatter()
        shortTime.timeStyle = .short
        shortTime.timeZone = .autoupdatingCurrent
        shortTime.locale = .autoupdatingCurrent
        self.shortTime = shortTime

        let ha = DateFormatter()
        ha.dateFormat = "ha"
        ha.timeZone = .autoupdatingCurrent
        ha.locale = .autoupdatingCurrent
        self.ha = ha

        let eee = DateFormatter()
        eee.dateFormat = "EEE"
        eee.timeZone = .autoupdatingCurrent
        eee.locale = .autoupdatingCurrent
        self.eee = eee
    }
}
