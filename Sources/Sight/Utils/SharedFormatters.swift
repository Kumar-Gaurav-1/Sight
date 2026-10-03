import Foundation

/// A centralized cache for computationally expensive formatters (DateFormatter, ISO8601DateFormatter)
/// using a thread-safe @unchecked Sendable class to support Swift strict concurrency.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let timeFormatter: DateFormatter
    public let hourFormatter: DateFormatter
    public let dayFormatter: DateFormatter
    public let shortDayFormatter: DateFormatter
    public let iso8601Formatter: ISO8601DateFormatter
    public let yyyyMMddFormatter: DateFormatter
    public let h_aFormatter: DateFormatter

    private init() {
        // short time style (e.g. 9:41 AM)
        timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        // ha style (e.g. 9AM)
        hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"

        // h a style (e.g. 9 AM)
        h_aFormatter = DateFormatter()
        h_aFormatter.dateFormat = "h a"

        // EEEE style (e.g. Monday)
        dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        // EEE style (e.g. Mon)
        shortDayFormatter = DateFormatter()
        shortDayFormatter.dateFormat = "EEE"

        // ISO8601 standard
        iso8601Formatter = ISO8601DateFormatter()

        // yyyy-MM-dd style
        yyyyMMddFormatter = DateFormatter()
        yyyyMMddFormatter.dateFormat = "yyyy-MM-dd"
    }
}
