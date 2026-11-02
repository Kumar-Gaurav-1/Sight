import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let hourAmPmSpace: DateFormatter
    public let dayOfWeek: DateFormatter
    public let fullDayOfWeek: DateFormatter
    public let iso8601: ISO8601DateFormatter
    public let ymd: DateFormatter

    private init() {
        let st = DateFormatter()
        st.timeStyle = .short
        st.timeZone = .autoupdatingCurrent
        st.locale = .autoupdatingCurrent
        self.shortTime = st

        let hap = DateFormatter()
        hap.dateFormat = "ha"
        hap.timeZone = .autoupdatingCurrent
        hap.locale = .autoupdatingCurrent
        self.hourAmPm = hap

        let haps = DateFormatter()
        haps.dateFormat = "h a"
        haps.timeZone = .autoupdatingCurrent
        haps.locale = .autoupdatingCurrent
        self.hourAmPmSpace = haps

        let dow = DateFormatter()
        dow.dateFormat = "EEE"
        dow.timeZone = .autoupdatingCurrent
        dow.locale = .autoupdatingCurrent
        self.dayOfWeek = dow

        let fdow = DateFormatter()
        fdow.dateFormat = "EEEE"
        fdow.timeZone = .autoupdatingCurrent
        fdow.locale = .autoupdatingCurrent
        self.fullDayOfWeek = fdow

        let iso = ISO8601DateFormatter()
        self.iso8601 = iso

        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        ymd.timeZone = .autoupdatingCurrent
        ymd.locale = .autoupdatingCurrent
        self.ymd = ymd
    }
}
