import Foundation

/// One contiguous stretch of a single activity on the timeline.
///
/// The timeline (an ordered list of these) is what lets us derive focus
/// sessions, context switches and breaks — things plain per-app totals can't
/// answer.
struct ActivitySegment: Codable, Hashable {
    let start: Date
    var end: Date
    let kind: Kind

    enum Kind: Codable, Hashable {
        case app(bundleId: String, name: String)
        case website(domain: String)
        case idle // a break / away-from-keyboard period
    }

    var seconds: TimeInterval { max(0, end.timeIntervalSince(start)) }

    var isIdle: Bool {
        if case .idle = kind { return true }
        return false
    }

    /// Stable identity used to detect context switches (nil for idle).
    var identity: String? {
        switch kind {
        case .app(let bundleId, _): return bundleId
        case .website(let domain): return domain
        case .idle: return nil
        }
    }
}
