import Foundation

/// Derived, human-friendly metrics for a day (or a merged range).
struct DayMetrics {
    var focusSeconds: Double        // time in "produktiv" activities
    var neutralSeconds: Double
    var distractingSeconds: Double
    var breakSeconds: Double        // idle periods counted as real breaks
    var breakCount: Int
    var contextSwitches: Int        // task switches between distinct activities
    var longestFocusSeconds: Double // longest uninterrupted productive run
    var focusSessionCount: Int      // productive runs >= focusSessionMinimum

    var activeSeconds: Double { focusSeconds + neutralSeconds + distractingSeconds }

    /// Context switches per active hour — a tidy "how scattered was I?" number.
    var switchesPerHour: Double {
        guard activeSeconds > 0 else { return 0 }
        return Double(contextSwitches) / (activeSeconds / 3600)
    }

    static let zero = DayMetrics(
        focusSeconds: 0, neutralSeconds: 0, distractingSeconds: 0,
        breakSeconds: 0, breakCount: 0, contextSwitches: 0,
        longestFocusSeconds: 0, focusSessionCount: 0
    )

    /// An idle period counts as a "break" only above this length.
    static let breakMinimum: Double = 2 * 60
    /// A productive run counts as a focus "session" above this length.
    static let focusSessionMinimum: Double = 15 * 60
}
