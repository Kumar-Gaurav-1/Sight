import Foundation

#if compiler(>=5.10)
fileprivate final class SharedFormatters: @unchecked Sendable {
    static let shared = SharedFormatters()

    let iso8601 = ISO8601DateFormatter()
    let dayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()
    let shortDayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
    let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    let ha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        return f
    }()
    let h_a: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()
    let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
#else
fileprivate final class SharedFormatters {
    static let shared = SharedFormatters()

    let iso8601 = ISO8601DateFormatter()
    let dayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()
    let shortDayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
    let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    let ha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        return f
    }()
    let h_a: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()
    let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
#endif

public struct Formatters {
    public static var iso8601: ISO8601DateFormatter { SharedFormatters.shared.iso8601 }
    public static var dayOfWeek: DateFormatter { SharedFormatters.shared.dayOfWeek }
    public static var shortDayOfWeek: DateFormatter { SharedFormatters.shared.shortDayOfWeek }
    public static var yyyyMMdd: DateFormatter { SharedFormatters.shared.yyyyMMdd }
    public static var ha: DateFormatter { SharedFormatters.shared.ha }
    public static var h_a: DateFormatter { SharedFormatters.shared.h_a }
    public static var shortTime: DateFormatter { SharedFormatters.shared.shortTime }
}
