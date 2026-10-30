import Foundation

// ⚡ Bolt: Globally cache computationally expensive DateFormatter instances
// This avoids repeated allocations in loops and frequent UI updates.
// @unchecked Sendable is safe here because the properties are constants (let)
// and DateFormatter is internally thread-safe when not mutated after setup.
#if compiler(>=5.10)
public final class Formatters: @unchecked Sendable {
    public static let shared = Formatters()

    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let shortDay: DateFormatter
    public let hourAmPmSpaced: DateFormatter
    public let fullDay: DateFormatter
    public let yyyyMMdd: DateFormatter

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

        let sd = DateFormatter()
        sd.dateFormat = "EEE"
        sd.timeZone = .autoupdatingCurrent
        sd.locale = .autoupdatingCurrent
        self.shortDay = sd

        let haps = DateFormatter()
        haps.dateFormat = "h a"
        haps.timeZone = .autoupdatingCurrent
        haps.locale = .autoupdatingCurrent
        self.hourAmPmSpaced = haps

        let fd = DateFormatter()
        fd.dateFormat = "EEEE"
        fd.timeZone = .autoupdatingCurrent
        fd.locale = .autoupdatingCurrent
        self.fullDay = fd

        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        ymd.timeZone = .autoupdatingCurrent
        ymd.locale = .autoupdatingCurrent
        self.yyyyMMdd = ymd
    }
}
#else
public final class Formatters: @unchecked Sendable {
    public static let shared = Formatters()

    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let shortDay: DateFormatter
    public let hourAmPmSpaced: DateFormatter
    public let fullDay: DateFormatter
    public let yyyyMMdd: DateFormatter

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

        let sd = DateFormatter()
        sd.dateFormat = "EEE"
        sd.timeZone = .autoupdatingCurrent
        sd.locale = .autoupdatingCurrent
        self.shortDay = sd

        let haps = DateFormatter()
        haps.dateFormat = "h a"
        haps.timeZone = .autoupdatingCurrent
        haps.locale = .autoupdatingCurrent
        self.hourAmPmSpaced = haps

        let fd = DateFormatter()
        fd.dateFormat = "EEEE"
        fd.timeZone = .autoupdatingCurrent
        fd.locale = .autoupdatingCurrent
        self.fullDay = fd

        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        ymd.timeZone = .autoupdatingCurrent
        ymd.locale = .autoupdatingCurrent
        self.yyyyMMdd = ymd
    }
}
#endif
