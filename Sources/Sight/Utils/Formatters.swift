import Foundation

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let hourAMPMFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let hourAMPMSpaceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let fullDayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let shortDayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    public let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    private init() {}
}
