import SwiftUI

/// Inline settings, shown in place of the main panel.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Text("Einstellungen").font(.headline)
                Spacer()
            }

            Text("Pomodoro")
                .font(.caption)
                .foregroundStyle(.secondary)

            Stepper("Fokus: \(settings.workMinutes) min",
                    value: $settings.workMinutes, in: 5...90, step: 5)
            Stepper("Kurze Pause: \(settings.shortBreakMinutes) min",
                    value: $settings.shortBreakMinutes, in: 1...30)
            Stepper("Lange Pause: \(settings.longBreakMinutes) min",
                    value: $settings.longBreakMinutes, in: 5...45, step: 5)
            Stepper("Pomodoros bis lange Pause: \(settings.pomodorosUntilLongBreak)",
                    value: $settings.pomodorosUntilLongBreak, in: 2...8)

            Divider()

            Text("Tracking")
                .font(.caption)
                .foregroundStyle(.secondary)

            Stepper("Leerlauf-Schwelle: \(settings.idleThresholdSeconds) s",
                    value: $settings.idleThresholdSeconds, in: 30...600, step: 30)
            Text("Nach so langer Inaktivität wird Zeit nicht mehr gezählt.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Stepper("Fokusphase ab: \(settings.focusPhaseMinutes) min",
                    value: $settings.focusPhaseMinutes, in: 5...60, step: 5)
            Text("So lange ununterbrochen produktiv = eine Fokusphase, deren Unterbrechungen gezählt werden.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Divider()

            Text("Alle Daten bleiben lokal auf deinem Mac.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
