import Foundation

#if compiler(>=5.10)
nonisolated(unsafe) fileprivate let _sharedShortTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

nonisolated(unsafe) fileprivate let _sharedHourAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter
}()

nonisolated(unsafe) fileprivate let _sharedHourSpaceAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    return formatter
}()

nonisolated(unsafe) fileprivate let _sharedWeekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

nonisolated(unsafe) fileprivate let _sharedISO8601Formatter = ISO8601DateFormatter()

nonisolated(unsafe) fileprivate let _sharedDateOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
#else
fileprivate let _sharedShortTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

fileprivate let _sharedHourAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter
}()

fileprivate let _sharedHourSpaceAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    return formatter
}()

fileprivate let _sharedWeekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

fileprivate let _sharedISO8601Formatter = ISO8601DateFormatter()

fileprivate let _sharedDateOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
#endif

/// A central repository for cached formatters.
/// Instantiating DateFormatter is computationally expensive, especially in tight loops or frequent UI updates.
/// By caching and reusing formatters, we improve performance and reduce memory allocations.
public enum Formatters {
    public static var shortTime: DateFormatter { _sharedShortTimeFormatter }
    public static var hourAMPM: DateFormatter { _sharedHourAMPMFormatter }
    public static var hourSpaceAMPM: DateFormatter { _sharedHourSpaceAMPMFormatter }
    public static var weekday: DateFormatter { _sharedWeekdayFormatter }
    public static var iso8601: ISO8601DateFormatter { _sharedISO8601Formatter }
    public static var dateOnly: DateFormatter { _sharedDateOnlyFormatter }
}

extension Formatters {
    #if compiler(>=5.10)
    nonisolated(unsafe) fileprivate static let _sharedShortWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    #else
    fileprivate static let _sharedShortWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    #endif

    public static var shortWeekday: DateFormatter { _sharedShortWeekdayFormatter }
}
