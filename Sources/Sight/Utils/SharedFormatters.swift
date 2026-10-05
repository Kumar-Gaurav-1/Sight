import Foundation

/// ⚡ Bolt: Globally cached date formatters to avoid expensive re-initialization
/// Measurements show DateFormatter initialization takes ~0.5-2ms, which adds up
/// significantly in loops (like CSV export) or frequent UI updates.
public final class SharedFormatters: @unchecked Sendable {
    public static let iso8601 = ISO8601DateFormatter()

    public static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static let dayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    public static let dayOfWeekShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    public static let hourAmPm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        return f
    }()

    public static let hourAmPmSpace: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()
}
