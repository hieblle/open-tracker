import Foundation

/// Higher-level "meta" insights derived from the day's timeline: how fragmented
/// the focus was, what kind of switching happened, and what interrupted flow.
struct FocusAnalysis {
    var focusBlockCount: Int            // number of productive runs (any length)
    var averageFocusBlockSeconds: Double
    var deepFocusSeconds: Double        // time in runs >= 15 min
    var scatteredFocusSeconds: Double   // time in runs < 15 min
    var appSwitches: Int                // switches between apps (incl. app <-> browser)
    var tabSwitches: Int                // switches between websites in the browser
    var interrupters: [FocusInterrupter] // what broke focus, most frequent first

    var totalFocusSeconds: Double { deepFocusSeconds + scatteredFocusSeconds }

    /// 0 = all focus in long deep blocks, 1 = entirely scattered.
    var fragmentation: Double {
        guard totalFocusSeconds > 0 else { return 0 }
        return scatteredFocusSeconds / totalFocusSeconds
    }

    /// A focus run must reach this length before an interruption "counts".
    static let interruptionFocusMinimum: Double = 3 * 60
}

/// An activity (or break) that repeatedly interrupted focus.
struct FocusInterrupter: Identifiable {
    let label: String
    let count: Int
    var id: String { label }
}
