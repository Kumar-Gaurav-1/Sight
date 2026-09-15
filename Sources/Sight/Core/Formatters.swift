import Foundation

public final class SharedFormatters {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()

    public let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let csvDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let dayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let shortDayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let hourOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let hourOnlyNoSpace: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
}

#if compiler(>=5.10)
extension SharedFormatters: @unchecked Sendable {}
#endif
