import Foundation

/// ⚡ Bolt: A globally shared cache for DateFormatters and ISO8601DateFormatters.
/// Instantiating DateFormatter is computationally expensive, especially within tight loops or
/// heavily re-rendered SwiftUI views. We cache them here to reuse instances.
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public let hourAmPm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    public let hourAmPmSpaced: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    public let shortWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    public let fullWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
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
