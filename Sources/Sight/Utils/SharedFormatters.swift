import Foundation

#if compiler(>=5.10)
public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter
    public let timeFormatter: DateFormatter
    public let dayFormatter: DateFormatter
    public let dateOnlyFormatter: DateFormatter
    public let hourFormatter: DateFormatter

    private init() {
        iso8601 = ISO8601DateFormatter()

        timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"
    }
}
#else
public final class SharedFormatters {
    public static let shared = SharedFormatters()

    public let iso8601: ISO8601DateFormatter
    public let timeFormatter: DateFormatter
    public let dayFormatter: DateFormatter
    public let dateOnlyFormatter: DateFormatter
    public let hourFormatter: DateFormatter

    private init() {
        iso8601 = ISO8601DateFormatter()

        timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"
    }
}
#endif
