import Foundation
import UserNotifications

/// Best-effort macOS notifications for Pomodoro phase changes.
///
/// Guarded behind a bundle-identifier check: when launched via `swift run`
/// there is no app bundle and `UNUserNotificationCenter` is unavailable, so we
/// simply skip (the audible chime still plays). Built as a real `.app`, banners
/// appear once the user grants permission.
final class Notifier {
    static let shared = Notifier()

    private var authorized = false
    private var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    private init() {}

    func requestAuthorizationIfNeeded() {
        guard isBundled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async { self?.authorized = granted }
        }
    }

    func notifyPhaseEnded(_ phase: PomodoroPhase) {
        guard isBundled, authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "OpenTracker"
        switch phase {
        case .work:
            content.body = "Fokus beendet — Zeit für eine Pause."
        case .shortBreak, .longBreak:
            content.body = "Pause vorbei — bereit für den nächsten Fokus?"
        }
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
