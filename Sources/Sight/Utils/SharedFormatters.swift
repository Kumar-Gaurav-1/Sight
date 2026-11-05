import Foundation

/// A globally shared cache of `DateFormatter` and `ISO8601DateFormatter` instances.
/// ⚡ Bolt Optimization: DateFormatter creation is highly computationally expensive.
/// Caching them here prevents significant CPU overhead and object allocations during UI rendering and data processing.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let timeShort: DateFormatter
    public let hourAmPmCompact: DateFormatter
    public let hourAmPm: DateFormatter
    public let dayOfWeekShort: DateFormatter
    public let dayOfWeekFull: DateFormatter
    public let yyyyMMdd: DateFormatter
    public let iso8601: ISO8601DateFormatter

    private init() {
        let timeShortFormatter = DateFormatter()
        timeShortFormatter.timeStyle = .short
        timeShortFormatter.timeZone = .autoupdatingCurrent
        timeShortFormatter.locale = .autoupdatingCurrent
        self.timeShort = timeShortFormatter

        let hourAmPmCompactFormatter = DateFormatter()
        hourAmPmCompactFormatter.dateFormat = "ha"
        hourAmPmCompactFormatter.timeZone = .autoupdatingCurrent
        hourAmPmCompactFormatter.locale = .autoupdatingCurrent
        self.hourAmPmCompact = hourAmPmCompactFormatter

        let hourAmPmFormatter = DateFormatter()
        hourAmPmFormatter.dateFormat = "h a"
        hourAmPmFormatter.timeZone = .autoupdatingCurrent
        hourAmPmFormatter.locale = .autoupdatingCurrent
        self.hourAmPm = hourAmPmFormatter

        let dayOfWeekShortFormatter = DateFormatter()
        dayOfWeekShortFormatter.dateFormat = "EEE"
        dayOfWeekShortFormatter.timeZone = .autoupdatingCurrent
        dayOfWeekShortFormatter.locale = .autoupdatingCurrent
        self.dayOfWeekShort = dayOfWeekShortFormatter

        let dayOfWeekFullFormatter = DateFormatter()
        dayOfWeekFullFormatter.dateFormat = "EEEE"
        dayOfWeekFullFormatter.timeZone = .autoupdatingCurrent
        dayOfWeekFullFormatter.locale = .autoupdatingCurrent
        self.dayOfWeekFull = dayOfWeekFullFormatter

        let yyyyMMddFormatter = DateFormatter()
        yyyyMMddFormatter.dateFormat = "yyyy-MM-dd"
        yyyyMMddFormatter.timeZone = .autoupdatingCurrent
        yyyyMMddFormatter.locale = .autoupdatingCurrent
        self.yyyyMMdd = yyyyMMddFormatter

        self.iso8601 = ISO8601DateFormatter()
    }
}
