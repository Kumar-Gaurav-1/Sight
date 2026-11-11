import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter
    public let haTime: DateFormatter
    public let eeeDay: DateFormatter
    public let eeeeDay: DateFormatter
    public let yyyyMMddDate: DateFormatter
    public let iso8601: ISO8601DateFormatter
    public let h_aTime: DateFormatter

    private init() {
        let st = DateFormatter()
        st.timeStyle = .short
        st.timeZone = .autoupdatingCurrent
        st.locale = .autoupdatingCurrent
        shortTime = st

        let ha = DateFormatter()
        ha.dateFormat = "ha"
        ha.timeZone = .autoupdatingCurrent
        ha.locale = .autoupdatingCurrent
        haTime = ha

        let h_a = DateFormatter()
        h_a.dateFormat = "h a"
        h_a.timeZone = .autoupdatingCurrent
        h_a.locale = .autoupdatingCurrent
        h_aTime = h_a

        let eee = DateFormatter()
        eee.dateFormat = "EEE"
        eee.timeZone = .autoupdatingCurrent
        eee.locale = .autoupdatingCurrent
        eeeDay = eee

        let eeee = DateFormatter()
        eeee.dateFormat = "EEEE"
        eeee.timeZone = .autoupdatingCurrent
        eeee.locale = .autoupdatingCurrent
        eeeeDay = eeee

        let yyyyMMdd = DateFormatter()
        yyyyMMdd.dateFormat = "yyyy-MM-dd"
        yyyyMMdd.timeZone = .autoupdatingCurrent
        yyyyMMdd.locale = .autoupdatingCurrent
        yyyyMMddDate = yyyyMMdd

        let iso = ISO8601DateFormatter()
        iso8601 = iso
    }
}
