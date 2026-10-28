import Foundation

/// ⚡ Bolt Optimization:
/// Globally cached formatters to prevent expensive re-instantiation during tight loops or view renders.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter
    public let shortTime: DateFormatter
    public let dayOfWeek: DateFormatter
    public let dayOfWeekShort: DateFormatter
    public let hourAmPm: DateFormatter
    public let hourAmPmCompact: DateFormatter
    public let yyyyMMdd: DateFormatter

    private init() {
        let iso = ISO8601DateFormatter()
        self.iso8601 = iso

        let short = DateFormatter()
        short.timeStyle = .short
        short.locale = .autoupdatingCurrent
        short.timeZone = .autoupdatingCurrent
        self.shortTime = short

        let day = DateFormatter()
        day.dateFormat = "EEEE"
        day.locale = .autoupdatingCurrent
        day.timeZone = .autoupdatingCurrent
        self.dayOfWeek = day

        let dayShort = DateFormatter()
        dayShort.dateFormat = "EEE"
        dayShort.locale = .autoupdatingCurrent
        dayShort.timeZone = .autoupdatingCurrent
        self.dayOfWeekShort = dayShort

        let hour = DateFormatter()
        hour.dateFormat = "h a"
        hour.locale = .autoupdatingCurrent
        hour.timeZone = .autoupdatingCurrent
        self.hourAmPm = hour

        let hourCompact = DateFormatter()
        hourCompact.dateFormat = "ha"
        hourCompact.locale = .autoupdatingCurrent
        hourCompact.timeZone = .autoupdatingCurrent
        self.hourAmPmCompact = hourCompact

        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        ymd.locale = .autoupdatingCurrent
        ymd.timeZone = .autoupdatingCurrent
        self.yyyyMMdd = ymd
    }
}
