import Foundation

/// A globally shared utility for common DateFormatters to improve performance.
/// DateFormatter instantiation is expensive and should be cached when possible.
public final class Formatters: @unchecked Sendable {
    public static let shared = Formatters()

    public let iso8601: ISO8601DateFormatter
    public let shortTime: DateFormatter
    public let dayOfWeek: DateFormatter
    public let dayOfWeekAbbreviated: DateFormatter
    public let hourAmPm: DateFormatter
    public let hourAmPmCondensed: DateFormatter
    public let yyyyMMdd: DateFormatter

    private init() {
        iso8601 = ISO8601DateFormatter()
        // Do NOT set timeZone for ISO8601 to keep it in GMT for correct sorting/sync.

        let st = DateFormatter()
        st.timeStyle = .short
        st.timeZone = .autoupdatingCurrent
        st.locale = .autoupdatingCurrent
        shortTime = st

        let dow = DateFormatter()
        dow.dateFormat = "EEEE"
        dow.timeZone = .autoupdatingCurrent
        dow.locale = .autoupdatingCurrent
        dayOfWeek = dow

        let dowAbbr = DateFormatter()
        dowAbbr.dateFormat = "EEE"
        dowAbbr.timeZone = .autoupdatingCurrent
        dowAbbr.locale = .autoupdatingCurrent
        dayOfWeekAbbreviated = dowAbbr

        let hap = DateFormatter()
        hap.dateFormat = "h a"
        hap.timeZone = .autoupdatingCurrent
        hap.locale = .autoupdatingCurrent
        hourAmPm = hap

        let hapc = DateFormatter()
        hapc.dateFormat = "ha"
        hapc.timeZone = .autoupdatingCurrent
        hapc.locale = .autoupdatingCurrent
        hourAmPmCondensed = hapc

        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        ymd.timeZone = .autoupdatingCurrent
        ymd.locale = .autoupdatingCurrent
        yyyyMMdd = ymd
    }
}
