import Foundation

/// A single row in an activity list: either an app or a visited website.
struct ActivitySummary: Identifiable {
    enum Kind: Hashable {
        case app(String)      // bundle identifier
        case website(String)  // domain
    }

    let kind: Kind
    let name: String
    let seconds: TimeInterval
    let category: AppCategory

    var id: String {
        switch kind {
        case .app(let bundleId): return "app:\(bundleId)"
        case .website(let domain): return "web:\(domain)"
        }
    }
}
