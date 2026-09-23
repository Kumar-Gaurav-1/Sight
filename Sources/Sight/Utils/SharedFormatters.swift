import Foundation

/// Globally shared date formatters to avoid expensive re-initializations and allocations.
/// Thread-safe via @unchecked Sendable since DateFormatter and ISO8601DateFormatter are safe to use
/// concurrently as long as their configuration is not mutated after initialization.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public let hourAmPmNoSpace: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    public let hourAmPmSpace: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    public let fullDayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    public let shortDayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    public let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()

    private init() {}
}
