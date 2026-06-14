import Foundation

/// Aggregated foreground usage for a single calendar day.
///
/// Tracks time per app *and* per browser domain. Browser time is attributed to
/// the visited domain (e.g. `github.com`) rather than to the browser app, which
/// is what makes the breakdown actually useful.
struct DayUsage: Codable {
    /// Calendar day in `yyyy-MM-dd` form (local time) — also the file name key.
    let dateKey: String

    /// Active foreground seconds keyed by app bundle identifier.
    var secondsByApp: [String: TimeInterval]

    /// Human-readable app names keyed by bundle identifier (captured live).
    var namesByApp: [String: String]

    /// Active foreground seconds keyed by website domain (e.g. `github.com`).
    var secondsByDomain: [String: TimeInterval]

    init(dateKey: String) {
        self.dateKey = dateKey
        self.secondsByApp = [:]
        self.namesByApp = [:]
        self.secondsByDomain = [:]
    }

    mutating func addApp(seconds: TimeInterval, bundleId: String, name: String) {
        secondsByApp[bundleId, default: 0] += seconds
        namesByApp[bundleId] = name
    }

    mutating func addDomain(seconds: TimeInterval, domain: String) {
        secondsByDomain[domain, default: 0] += seconds
    }

    var totalSeconds: TimeInterval {
        secondsByApp.values.reduce(0, +) + secondsByDomain.values.reduce(0, +)
    }

    // Custom decoding so older files (without `secondsByDomain`) still load.
    enum CodingKeys: String, CodingKey {
        case dateKey, secondsByApp, namesByApp, secondsByDomain
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dateKey = try c.decode(String.self, forKey: .dateKey)
        secondsByApp = try c.decodeIfPresent([String: TimeInterval].self, forKey: .secondsByApp) ?? [:]
        namesByApp = try c.decodeIfPresent([String: String].self, forKey: .namesByApp) ?? [:]
        secondsByDomain = try c.decodeIfPresent([String: TimeInterval].self, forKey: .secondsByDomain) ?? [:]
    }
}
