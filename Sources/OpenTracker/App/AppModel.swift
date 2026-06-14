import Foundation

/// Single shared container for the app's long-lived services.
///
/// A singleton keeps construction (and the background tracking timer) to exactly
/// one instance, even though SwiftUI may re-create the `App` value.
final class AppModel {
    static let shared = AppModel()

    let settings = AppSettings()
    let categories = CategoryStore()
    let projects = ProjectStore()
    let goals = GoalStore()
    let usage: UsageStore
    let pomodoro: PomodoroTimer
    let tracker: ActivityTracker

    private init() {
        let usage = UsageStore()
        self.usage = usage
        self.pomodoro = PomodoroTimer(settings: settings)
        self.tracker = ActivityTracker(settings: settings, usage: usage)
    }

    /// Idempotent — safe to call once from the app delegate on launch.
    func start() {
        tracker.start()
        Notifier.shared.requestAuthorizationIfNeeded()
    }
}
