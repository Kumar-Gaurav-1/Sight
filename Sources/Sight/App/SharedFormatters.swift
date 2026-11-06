import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter
    public let hourAmPm: DateFormatter
    public let hourSpaceAmPm: DateFormatter
    public let dayOfWeekShort: DateFormatter
    public let dayOfWeekFull: DateFormatter
    public let yearMonthDay: DateFormatter
    public let iso8601: ISO8601DateFormatter

    private init() {
        func createFormatter() -> DateFormatter {
            let f = DateFormatter()
            f.timeZone = .autoupdatingCurrent
            f.locale = .autoupdatingCurrent
            return f
        }

        let st = createFormatter()
        st.timeStyle = .short
        shortTime = st

        let hAP = createFormatter()
        hAP.dateFormat = "ha"
        hourAmPm = hAP

        let hSAP = createFormatter()
        hSAP.dateFormat = "h a"
        hourSpaceAmPm = hSAP

        let dOWS = createFormatter()
        dOWS.dateFormat = "EEE"
        dayOfWeekShort = dOWS

        let dOWF = createFormatter()
        dOWF.dateFormat = "EEEE"
        dayOfWeekFull = dOWF

        let yMD = createFormatter()
        yMD.dateFormat = "yyyy-MM-dd"
        yearMonthDay = yMD

        iso8601 = ISO8601DateFormatter()
    }
}
