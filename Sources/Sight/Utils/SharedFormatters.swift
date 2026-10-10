import Foundation

/// A globally shared, thread-safe cache for DateFormatters to improve performance
/// by avoiding repeated initializations.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    private init() {}

    /// Standard ISO8601 formatter
    public let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    /// Short time style formatter (e.g., "9:41 AM")
    public let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Day of week formatter (e.g., "Monday")
    public let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// Short day of week formatter (e.g., "Mon")
    public let shortDayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    /// Year-Month-Day formatter (e.g., "2023-10-25")
    public let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Hour AM/PM formatter (e.g., "9AM")
    public let hourAmPm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()
}
