import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let shortDayName: DateFormatter
    public let fullDayName: DateFormatter
    public let iso8601: ISO8601DateFormatter
    public let yyyyMMdd: DateFormatter
    public let hourAmPmSpaced: DateFormatter

    private init() {
        shortTime = DateFormatter()
        shortTime.timeStyle = .short
        shortTime.timeZone = .autoupdatingCurrent
        shortTime.locale = .autoupdatingCurrent

        hourAmPm = DateFormatter()
        hourAmPm.dateFormat = "ha"
        hourAmPm.timeZone = .autoupdatingCurrent
        hourAmPm.locale = .autoupdatingCurrent

        shortDayName = DateFormatter()
        shortDayName.dateFormat = "EEE"
        shortDayName.timeZone = .autoupdatingCurrent
        shortDayName.locale = .autoupdatingCurrent

        fullDayName = DateFormatter()
        fullDayName.dateFormat = "EEEE"
        fullDayName.timeZone = .autoupdatingCurrent
        fullDayName.locale = .autoupdatingCurrent

        iso8601 = ISO8601DateFormatter()
        // Do not set timezone to autoupdatingCurrent for iso8601

        yyyyMMdd = DateFormatter()
        yyyyMMdd.dateFormat = "yyyy-MM-dd"
        yyyyMMdd.timeZone = .autoupdatingCurrent
        yyyyMMdd.locale = .autoupdatingCurrent

        hourAmPmSpaced = DateFormatter()
        hourAmPmSpaced.dateFormat = "h a"
        hourAmPmSpaced.timeZone = .autoupdatingCurrent
        hourAmPmSpaced.locale = .autoupdatingCurrent
    }
}
