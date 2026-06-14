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
        case idle                            // auto-detected inactivity (a break)
        case manualBreak(ManualBreakReason)  // user-marked pause or distraction
    }

    var seconds: TimeInterval { max(0, end.timeIntervalSince(start)) }

    /// True for anything that breaks focus and is not active app/website use.
    var interruptsFocus: Bool {
        switch kind {
        case .idle, .manualBreak: return true
        case .app, .website: return false
        }
    }

    /// True for time that counts as a recovery break (not a distraction).
    var isRecoveryBreak: Bool {
        switch kind {
        case .idle, .manualBreak(.recovery): return true
        default: return false
        }
    }

    /// Stable identity used to detect context switches (nil for non-active).
    var identity: String? {
        switch kind {
        case .app(let bundleId, _): return bundleId
        case .website(let domain): return domain
        case .idle, .manualBreak: return nil
        }
    }
}

/// Why a manual break was started.
enum ManualBreakReason: String, Codable, Hashable {
    case recovery     // intentional rest (coffee, walk) → neutral
    case distraction  // external interruption → counts as a distraction
}
