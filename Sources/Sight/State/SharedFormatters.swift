import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let timeShortFormatter: DateFormatter
    public let hourAmPmFormatter: DateFormatter
    public let hourAmPmNoSpaceFormatter: DateFormatter
    public let dayOfWeekFormatter: DateFormatter
    public let dayOfWeekShortFormatter: DateFormatter
    public let iso8601Formatter: ISO8601DateFormatter
    public let dateOnlyFormatter: DateFormatter

    private init() {
        timeShortFormatter = DateFormatter()
        timeShortFormatter.timeStyle = .short
        timeShortFormatter.timeZone = .autoupdatingCurrent
        timeShortFormatter.locale = .autoupdatingCurrent

        hourAmPmFormatter = DateFormatter()
        hourAmPmFormatter.dateFormat = "h a"
        hourAmPmFormatter.timeZone = .autoupdatingCurrent
        hourAmPmFormatter.locale = .autoupdatingCurrent

        hourAmPmNoSpaceFormatter = DateFormatter()
        hourAmPmNoSpaceFormatter.dateFormat = "ha"
        hourAmPmNoSpaceFormatter.timeZone = .autoupdatingCurrent
        hourAmPmNoSpaceFormatter.locale = .autoupdatingCurrent

        dayOfWeekFormatter = DateFormatter()
        dayOfWeekFormatter.dateFormat = "EEEE"
        dayOfWeekFormatter.timeZone = .autoupdatingCurrent
        dayOfWeekFormatter.locale = .autoupdatingCurrent

        dayOfWeekShortFormatter = DateFormatter()
        dayOfWeekShortFormatter.dateFormat = "EEE"
        dayOfWeekShortFormatter.timeZone = .autoupdatingCurrent
        dayOfWeekShortFormatter.locale = .autoupdatingCurrent

        iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.timeZone = .autoupdatingCurrent

        dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = .autoupdatingCurrent
        dateOnlyFormatter.locale = .autoupdatingCurrent
    }
}
