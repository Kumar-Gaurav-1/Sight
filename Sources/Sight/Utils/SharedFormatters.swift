import Foundation

/// ⚡ Bolt Performance Optimization:
/// DateFormatter and ISO8601DateFormatter initialization is computationally expensive.
/// This globally cached singleton prevents repetitive initialization during UI renders (like charts)
/// and loops (like CSV exports), saving CPU cycles and memory allocations.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter
    public let dayOfWeekFull: DateFormatter
    public let dayOfWeekShort: DateFormatter
    public let shortTime: DateFormatter
    public let hourOnly: DateFormatter
    public let hourWithSpace: DateFormatter
    public let yyyyMMdd: DateFormatter

    private init() {
        iso8601 = ISO8601DateFormatter()

        let fullDay = DateFormatter()
        fullDay.dateFormat = "EEEE"
        dayOfWeekFull = fullDay

        let shortDay = DateFormatter()
        shortDay.dateFormat = "EEE"
        dayOfWeekShort = shortDay

        let shortTimeFormatter = DateFormatter()
        shortTimeFormatter.timeStyle = .short
        shortTimeFormatter.dateStyle = .none
        shortTime = shortTimeFormatter

        let hour = DateFormatter()
        hour.dateFormat = "ha"
        hourOnly = hour

        let hourSpace = DateFormatter()
        hourSpace.dateFormat = "h a"
        hourWithSpace = hourSpace

        let yyyyMMddFormatter = DateFormatter()
        yyyyMMddFormatter.dateFormat = "yyyy-MM-dd"
        yyyyMMdd = yyyyMMddFormatter
    }
}
