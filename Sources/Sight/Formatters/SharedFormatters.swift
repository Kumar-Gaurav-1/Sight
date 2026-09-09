import Foundation

#if compiler(>=5.10)
public enum SharedFormatters {
    nonisolated(unsafe) public static let timeShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    nonisolated(unsafe) public static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    nonisolated(unsafe) public static let shortDayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    nonisolated(unsafe) public static let hourAmPmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    nonisolated(unsafe) public static let hourAmPmSpacedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    nonisolated(unsafe) public static let yearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    nonisolated(unsafe) public static let iso8601Formatter: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
}
#else
public enum SharedFormatters {
    public static let timeShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    public static let shortDayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    public static let hourAmPmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    public static let hourAmPmSpacedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    public static let yearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static let iso8601Formatter: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
}
#endif
