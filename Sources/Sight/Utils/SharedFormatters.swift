import Foundation

#if compiler(>=5.10)
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()
    public let timeFormatter: DateFormatter
    public let iso8601Formatter: ISO8601DateFormatter
    public let dayNameFormatter: DateFormatter
    public let fullDateFormatter: DateFormatter
    public let shortDayNameFormatter: DateFormatter
    public let hourFormatter: DateFormatter

    private init() {
        let tf = DateFormatter()
        tf.timeStyle = .short
        self.timeFormatter = tf

        self.iso8601Formatter = ISO8601DateFormatter()

        let dnf = DateFormatter()
        dnf.dateFormat = "EEEE"
        self.dayNameFormatter = dnf

        let fdf = DateFormatter()
        fdf.dateFormat = "yyyy-MM-dd"
        self.fullDateFormatter = fdf

        let sdnf = DateFormatter()
        sdnf.dateFormat = "EEE"
        self.shortDayNameFormatter = sdnf

        let hf = DateFormatter()
        hf.dateFormat = "ha"
        self.hourFormatter = hf
    }
}
#else
public final class SharedFormatters {
    public static let shared = SharedFormatters()
    public let timeFormatter: DateFormatter
    public let iso8601Formatter: ISO8601DateFormatter
    public let dayNameFormatter: DateFormatter
    public let fullDateFormatter: DateFormatter
    public let shortDayNameFormatter: DateFormatter
    public let hourFormatter: DateFormatter

    private init() {
        let tf = DateFormatter()
        tf.timeStyle = .short
        self.timeFormatter = tf

        self.iso8601Formatter = ISO8601DateFormatter()

        let dnf = DateFormatter()
        dnf.dateFormat = "EEEE"
        self.dayNameFormatter = dnf

        let fdf = DateFormatter()
        fdf.dateFormat = "yyyy-MM-dd"
        self.fullDateFormatter = fdf

        let sdnf = DateFormatter()
        sdnf.dateFormat = "EEE"
        self.shortDayNameFormatter = sdnf

        let hf = DateFormatter()
        hf.dateFormat = "ha"
        self.hourFormatter = hf
    }
}
#endif
