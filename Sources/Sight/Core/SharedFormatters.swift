import Foundation

#if compiler(>=5.10)

nonisolated(unsafe) public let sharedISO8601Formatter: ISO8601DateFormatter = {
    return ISO8601DateFormatter()
}()

nonisolated(unsafe) public let sharedShortTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

nonisolated(unsafe) public let sharedHourAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter
}()

nonisolated(unsafe) public let sharedHourSpacedAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    return formatter
}()

nonisolated(unsafe) public let sharedWeekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

nonisolated(unsafe) public let sharedShortWeekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
}()

nonisolated(unsafe) public let sharedYMDFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

#else

public let sharedISO8601Formatter: ISO8601DateFormatter = {
    return ISO8601DateFormatter()
}()

public let sharedShortTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

public let sharedHourAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter
}()

public let sharedHourSpacedAMPMFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    return formatter
}()

public let sharedWeekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

public let sharedShortWeekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
}()

public let sharedYMDFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

#endif
