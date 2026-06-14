import Foundation
import Combine

/// User-configurable preferences, persisted in `UserDefaults`.
///
/// Kept as an `ObservableObject` (rather than `@Observable`) so we can lean on
/// `@Published`'s `didSet` for transparent persistence and bind directly to it
/// from `Stepper`s in the settings UI.
final class AppSettings: ObservableObject {
    @Published var workMinutes: Int { didSet { defaults.set(workMinutes, forKey: "workMinutes") } }
    @Published var shortBreakMinutes: Int { didSet { defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes") } }
    @Published var longBreakMinutes: Int { didSet { defaults.set(longBreakMinutes, forKey: "longBreakMinutes") } }
    @Published var pomodorosUntilLongBreak: Int { didSet { defaults.set(pomodorosUntilLongBreak, forKey: "pomodorosUntilLongBreak") } }
    @Published var idleThresholdSeconds: Int { didSet { defaults.set(idleThresholdSeconds, forKey: "idleThresholdSeconds") } }
    @Published var focusPhaseMinutes: Int { didSet { defaults.set(focusPhaseMinutes, forKey: "focusPhaseMinutes") } }

    private let defaults = UserDefaults.standard

    init() {
        let d = UserDefaults.standard
        // `object(forKey:) as? Int` distinguishes "never set" (nil) from a real 0.
        workMinutes = d.object(forKey: "workMinutes") as? Int ?? 25
        shortBreakMinutes = d.object(forKey: "shortBreakMinutes") as? Int ?? 5
        longBreakMinutes = d.object(forKey: "longBreakMinutes") as? Int ?? 15
        pomodorosUntilLongBreak = d.object(forKey: "pomodorosUntilLongBreak") as? Int ?? 4
        idleThresholdSeconds = d.object(forKey: "idleThresholdSeconds") as? Int ?? 120
        focusPhaseMinutes = d.object(forKey: "focusPhaseMinutes") as? Int ?? 15
    }
}
