import Foundation

public final class SharedFormatters: @unchecked Sendable {
#if compiler(>=5.10)
    nonisolated(unsafe) public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    nonisolated(unsafe) public static let hourAmPmNoSpace: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        return f
    }()

    nonisolated(unsafe) public static let shortDayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    nonisolated(unsafe) public static let hourAmPm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()

    nonisolated(unsafe) public static let fullDayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    nonisolated(unsafe) public static let yearMonthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    nonisolated(unsafe) public static let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
#else
    public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    public static let hourAmPmNoSpace: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        return f
    }()

    public static let shortDayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    public static let hourAmPm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()

    public static let fullDayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    public static let yearMonthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
#endif
}
