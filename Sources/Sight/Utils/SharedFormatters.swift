import Foundation

/// DateFormatter and ISO8601DateFormatter instantiations are computationally expensive.
/// We globally cache and reuse these shared instances to eliminate redundant memory allocations
/// and improve performance, especially during loops and frequent SwiftUI render passes.


#if compiler(>=5.10)
nonisolated(unsafe) public let sharedISO8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    return formatter
}()

nonisolated(unsafe) public let sharedDateFormatterEEEE: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

nonisolated(unsafe) public let sharedDateFormatterYYYYMMDD: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

nonisolated(unsafe) public let sharedDateFormatterHA: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    return formatter
}()

nonisolated(unsafe) public let sharedDateFormatterHaNoSpace: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter
}()

nonisolated(unsafe) public let sharedDateFormatterTimeShort: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

nonisolated(unsafe) public let sharedDateFormatterEEE: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
}()
#else
public let sharedISO8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    return formatter
}()

public let sharedDateFormatterEEEE: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

public let sharedDateFormatterYYYYMMDD: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

public let sharedDateFormatterHA: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    return formatter
}()

public let sharedDateFormatterHaNoSpace: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter
}()

public let sharedDateFormatterTimeShort: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

public let sharedDateFormatterEEE: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
}()
#endif
