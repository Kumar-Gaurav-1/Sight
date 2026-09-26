import Foundation

/// A globally shared, thread-safe provider of highly-used formatters
/// to prevent expensive redundant memory allocations.
#if compiler(>=5.10)
nonisolated(unsafe) public let SharedFormatters = FormatterCache()
#else
public let SharedFormatters = FormatterCache()
#endif

public final class FormatterCache: @unchecked Sendable {

    public let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    public let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public let dayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    public let shortDayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    public let hourAmPm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    public let hourAmPmNoSpace: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    public let isoDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
