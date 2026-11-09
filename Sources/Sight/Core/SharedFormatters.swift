import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter
    public let hourAmPmNoSpace: DateFormatter // "ha"
    public let hourAmPm: DateFormatter // "h a"
    public let dayOfWeekShort: DateFormatter // "EEE"
    public let dayOfWeekFull: DateFormatter // "EEEE"
    public let yearMonthDay: DateFormatter // "yyyy-MM-dd"
    public let iso8601: ISO8601DateFormatter

    private init() {
        let shortTime = DateFormatter()
        shortTime.timeStyle = .short
        shortTime.timeZone = .autoupdatingCurrent
        shortTime.locale = .autoupdatingCurrent
        self.shortTime = shortTime

        let hourAmPmNoSpace = DateFormatter()
        hourAmPmNoSpace.dateFormat = "ha"
        hourAmPmNoSpace.timeZone = .autoupdatingCurrent
        hourAmPmNoSpace.locale = .autoupdatingCurrent
        self.hourAmPmNoSpace = hourAmPmNoSpace

        let hourAmPm = DateFormatter()
        hourAmPm.dateFormat = "h a"
        hourAmPm.timeZone = .autoupdatingCurrent
        hourAmPm.locale = .autoupdatingCurrent
        self.hourAmPm = hourAmPm

        let dayOfWeekShort = DateFormatter()
        dayOfWeekShort.dateFormat = "EEE"
        dayOfWeekShort.timeZone = .autoupdatingCurrent
        dayOfWeekShort.locale = .autoupdatingCurrent
        self.dayOfWeekShort = dayOfWeekShort

        let dayOfWeekFull = DateFormatter()
        dayOfWeekFull.dateFormat = "EEEE"
        dayOfWeekFull.timeZone = .autoupdatingCurrent
        dayOfWeekFull.locale = .autoupdatingCurrent
        self.dayOfWeekFull = dayOfWeekFull

        let yearMonthDay = DateFormatter()
        yearMonthDay.dateFormat = "yyyy-MM-dd"
        yearMonthDay.timeZone = .autoupdatingCurrent
        yearMonthDay.locale = .autoupdatingCurrent
        self.yearMonthDay = yearMonthDay

        let iso8601 = ISO8601DateFormatter()
        self.iso8601 = iso8601
    }
}
