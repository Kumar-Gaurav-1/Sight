import Foundation

/// Shared DateFormatters for performance optimization
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let hourAmPmSpaced: DateFormatter
    public let dayOfWeekShort: DateFormatter
    public let dayOfWeekFull: DateFormatter
    public let yyyyMMdd: DateFormatter
    public let iso8601: ISO8601DateFormatter

    private init() {
        let shortTime = DateFormatter()
        shortTime.timeZone = .autoupdatingCurrent
        shortTime.locale = .autoupdatingCurrent
        shortTime.timeStyle = .short
        self.shortTime = shortTime

        let hourAmPm = DateFormatter()
        hourAmPm.timeZone = .autoupdatingCurrent
        hourAmPm.locale = .autoupdatingCurrent
        hourAmPm.dateFormat = "ha"
        self.hourAmPm = hourAmPm

        let hourAmPmSpaced = DateFormatter()
        hourAmPmSpaced.timeZone = .autoupdatingCurrent
        hourAmPmSpaced.locale = .autoupdatingCurrent
        hourAmPmSpaced.dateFormat = "h a"
        self.hourAmPmSpaced = hourAmPmSpaced

        let dayOfWeekShort = DateFormatter()
        dayOfWeekShort.timeZone = .autoupdatingCurrent
        dayOfWeekShort.locale = .autoupdatingCurrent
        dayOfWeekShort.dateFormat = "EEE"
        self.dayOfWeekShort = dayOfWeekShort

        let dayOfWeekFull = DateFormatter()
        dayOfWeekFull.timeZone = .autoupdatingCurrent
        dayOfWeekFull.locale = .autoupdatingCurrent
        dayOfWeekFull.dateFormat = "EEEE"
        self.dayOfWeekFull = dayOfWeekFull

        let yyyyMMdd = DateFormatter()
        yyyyMMdd.timeZone = .autoupdatingCurrent
        yyyyMMdd.locale = .autoupdatingCurrent
        yyyyMMdd.dateFormat = "yyyy-MM-dd"
        self.yyyyMMdd = yyyyMMdd

        let iso8601 = ISO8601DateFormatter()
        // Default ISO8601DateFormatter uses GMT (Z), which is critical for lexicographical sorting
        self.iso8601 = iso8601
    }
}
