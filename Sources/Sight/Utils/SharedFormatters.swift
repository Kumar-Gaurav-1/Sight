import Foundation

// MARK: - Performance Optimization: Shared Formatters
// DateFormatter and ISO8601DateFormatter are computationally expensive to instantiate.
// We cache and share them globally to prevent redundant allocations during tight loops or frequent UI updates.

public final class SharedFormatters: @unchecked Sendable {
    public static let shared = SharedFormatters()

    public let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    public let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private init() {}
}
