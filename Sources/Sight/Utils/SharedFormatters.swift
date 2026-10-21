import Foundation

/// Shared formatters to improve performance by avoiding repeated instantiation.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()

    public let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public let ha: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    public let h_a: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    public let eee: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    public let eeee: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    public let yyyy_MM_dd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private init() {}
}
