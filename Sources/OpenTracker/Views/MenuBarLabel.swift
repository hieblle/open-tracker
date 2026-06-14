import SwiftUI

/// What shows up in the macOS menu bar.
/// Reflects a manual pause/distraction first, then a running Pomodoro,
/// otherwise a quiet timer glyph.
struct MenuBarLabel: View {
    @Environment(PomodoroTimer.self) private var pomodoro
    @Environment(ActivityTracker.self) private var tracker

    var body: some View {
        if tracker.isPaused {
            Image(systemName: "pause.circle.fill")
        } else if tracker.isDistracted {
            Image(systemName: "exclamationmark.triangle.fill")
        } else if pomodoro.isRunning {
            HStack(spacing: 4) {
                Image(systemName: pomodoro.phase.symbolName)
                Text(formatClock(pomodoro.remaining))
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "timer")
        }
    }
}
