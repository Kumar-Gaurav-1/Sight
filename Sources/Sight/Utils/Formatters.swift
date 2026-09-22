import Foundation

/// Shared formatters for performance optimization.
/// Instantiating DateFormatter or ISO8601DateFormatter is computationally expensive.
/// We cache and reuse these formatters to avoid redundant memory allocations, especially in loops and frequently called UI code.
public enum SharedFormatters {
#if compiler(>=5.10)
    nonisolated(unsafe) public static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    nonisolated(unsafe) public static let haTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    nonisolated(unsafe) public static let eeeDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    nonisolated(unsafe) public static let eeeeDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    nonisolated(unsafe) public static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    nonisolated(unsafe) public static let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
#else
    public static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public static let haTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    public static let eeeDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    public static let eeeeDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    public static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
#endif
}
