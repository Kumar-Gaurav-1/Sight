import Foundation

public enum DateFormatterCache {
    #if compiler(>=5.10)
    nonisolated(unsafe) public static let sharedISO8601 = ISO8601DateFormatter()
    nonisolated(unsafe) public static let sharedYYYYMMDD: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    #else
    public static let sharedISO8601 = ISO8601DateFormatter()
    public static let sharedYYYYMMDD: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    #endif
}
