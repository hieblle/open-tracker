import Foundation

/// Aggregated foreground app usage for a single calendar day.
///
/// We deliberately store *aggregates* (seconds per app) rather than every
/// switch event: it keeps the on-disk footprint tiny and is all we need to
/// answer "which apps did I use, and for how long?".
struct DayUsage: Codable {
    /// Calendar day in `yyyy-MM-dd` form (local time) — also the file name key.
    let dateKey: String

    /// Active foreground seconds keyed by app bundle identifier.
    var secondsByApp: [String: TimeInterval]

    /// Human-readable app names keyed by bundle identifier (captured live).
    var namesByApp: [String: String]

    init(dateKey: String) {
        self.dateKey = dateKey
        self.secondsByApp = [:]
        self.namesByApp = [:]
    }

    mutating func add(seconds: TimeInterval, bundleId: String, name: String) {
        secondsByApp[bundleId, default: 0] += seconds
        namesByApp[bundleId] = name
    }

    var totalSeconds: TimeInterval {
        secondsByApp.values.reduce(0, +)
    }
}
