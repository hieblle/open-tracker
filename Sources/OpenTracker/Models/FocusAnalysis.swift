import SwiftUI

/// What kind of thing broke a focus phase.
enum InterruptionKind {
    case distraction // switched to a distracting activity
    case neutral     // switched to a neutral activity
    case pause       // went idle / took a break

    var title: String {
        switch self {
        case .distraction: return "Ablenkung"
        case .neutral: return "Neutrales"
        case .pause: return "Pause"
        }
    }

    var color: Color {
        switch self {
        case .distraction: return AppCategory.distracting.color
        case .neutral: return AppCategory.neutral.color
        case .pause: return .blue
        }
    }
}

/// An activity (or break) that repeatedly interrupted focus.
struct FocusInterrupter: Identifiable {
    let label: String
    let count: Int
    let kind: InterruptionKind
    var id: String { label }
}

/// Higher-level "meta" insights derived from the day's timeline — centered on
/// **interruptions of focus phases** rather than raw context switches.
///
/// A "focus phase" is an uninterrupted productive run of at least
/// `interruptionFocusMinimum`. Switching between *productive* activities does
/// not break a phase — only a non-productive activity or a break does.
struct FocusAnalysis {
    var focusBlockCount: Int            // all productive runs (any length)
    var averageFocusBlockSeconds: Double
    var deepFocusSeconds: Double        // time in runs >= 15 min
    var scatteredFocusSeconds: Double   // time in runs < 15 min
    var appSwitches: Int                // raw app switches (secondary)
    var tabSwitches: Int                // raw browser tab switches (secondary)

    var focusPhaseCount: Int            // runs that reached the focus threshold
    var interruptionsByDistraction: Int
    var interruptionsByNeutral: Int
    var interruptionsByBreak: Int
    var interrupters: [FocusInterrupter] // what broke focus, most frequent first

    var focusInterruptions: Int {
        interruptionsByDistraction + interruptionsByNeutral + interruptionsByBreak
    }

    var totalFocusSeconds: Double { deepFocusSeconds + scatteredFocusSeconds }

    /// 0 = all focus in long deep blocks, 1 = entirely scattered.
    var fragmentation: Double {
        guard totalFocusSeconds > 0 else { return 0 }
        return scatteredFocusSeconds / totalFocusSeconds
    }

    /// How often focus gets broken per hour of actual focus time.
    var interruptionsPerFocusHour: Double {
        guard totalFocusSeconds > 0 else { return 0 }
        return Double(focusInterruptions) / (totalFocusSeconds / 3600)
    }

    /// A productive run must reach this length to count as a "focus phase".
    static let interruptionFocusMinimum: Double = 3 * 60
}
