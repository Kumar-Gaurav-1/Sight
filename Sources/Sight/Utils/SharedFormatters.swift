import Foundation

/// A globally shared cache for expensive formatter instances to optimize performance.
/// DateFormatter and ISO8601DateFormatter are expensive to create.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTimeFormatter: DateFormatter
    public let hourAmPmFormatter: DateFormatter
    public let dayOfWeekFormatter: DateFormatter
    public let yyyyMMddFormatter: DateFormatter
    public let iso8601Formatter: ISO8601DateFormatter

    private init() {
        let shortTime = DateFormatter()
        shortTime.timeStyle = .short
        shortTime.locale = .autoupdatingCurrent
        shortTime.timeZone = .autoupdatingCurrent
        self.shortTimeFormatter = shortTime

        let hourAmPm = DateFormatter()
        hourAmPm.dateFormat = "h a"
        hourAmPm.locale = .autoupdatingCurrent
        hourAmPm.timeZone = .autoupdatingCurrent
        self.hourAmPmFormatter = hourAmPm

        let dayOfWeek = DateFormatter()
        dayOfWeek.dateFormat = "EEEE"
        dayOfWeek.locale = .autoupdatingCurrent
        dayOfWeek.timeZone = .autoupdatingCurrent
        self.dayOfWeekFormatter = dayOfWeek

        let yyyyMMdd = DateFormatter()
        yyyyMMdd.dateFormat = "yyyy-MM-dd"
        yyyyMMdd.locale = .autoupdatingCurrent
        yyyyMMdd.timeZone = .autoupdatingCurrent
        self.yyyyMMddFormatter = yyyyMMdd

        let iso8601 = ISO8601DateFormatter()
        self.iso8601Formatter = iso8601
    }

    // Fallback for short day "EEE"
    public let shortDayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        return f
    }()

    // Fallback for hour no space "ha"
    public let hourAmPmNoSpaceFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        return f
    }()
}
