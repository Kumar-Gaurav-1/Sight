import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter
    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let hourAmPmNoSpace: DateFormatter
    public let dayOfWeekShort: DateFormatter
    public let dayOfWeekLong: DateFormatter
    public let yearMonthDay: DateFormatter

    private init() {
        // ISO8601 must keep default Z timezone.
        iso8601 = ISO8601DateFormatter()

        shortTime = DateFormatter()
        shortTime.timeStyle = .short
        shortTime.timeZone = .autoupdatingCurrent
        shortTime.locale = .autoupdatingCurrent

        hourAmPm = DateFormatter()
        hourAmPm.dateFormat = "h a"
        hourAmPm.timeZone = .autoupdatingCurrent
        hourAmPm.locale = .autoupdatingCurrent

        hourAmPmNoSpace = DateFormatter()
        hourAmPmNoSpace.dateFormat = "ha"
        hourAmPmNoSpace.timeZone = .autoupdatingCurrent
        hourAmPmNoSpace.locale = .autoupdatingCurrent

        // e.g. EEE
        dayOfWeekShort = DateFormatter()
        dayOfWeekShort.dateFormat = "EEE"
        dayOfWeekShort.timeZone = .autoupdatingCurrent
        dayOfWeekShort.locale = .autoupdatingCurrent

        // e.g. EEEE
        dayOfWeekLong = DateFormatter()
        dayOfWeekLong.dateFormat = "EEEE"
        dayOfWeekLong.timeZone = .autoupdatingCurrent
        dayOfWeekLong.locale = .autoupdatingCurrent

        // e.g. yyyy-MM-dd
        yearMonthDay = DateFormatter()
        yearMonthDay.dateFormat = "yyyy-MM-dd"
        yearMonthDay.timeZone = .autoupdatingCurrent
        yearMonthDay.locale = .autoupdatingCurrent
    }
}
