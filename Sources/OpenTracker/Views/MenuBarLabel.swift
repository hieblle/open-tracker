import SwiftUI

/// What shows up in the macOS menu bar.
/// Live countdown while a Pomodoro runs, otherwise a quiet timer glyph.
struct MenuBarLabel: View {
    @Environment(PomodoroTimer.self) private var pomodoro

    var body: some View {
        if pomodoro.isRunning {
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
