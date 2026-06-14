import SwiftUI

/// Pomodoro ring + controls.
struct PomodoroView: View {
    @Environment(PomodoroTimer.self) private var pomodoro

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(pomodoro.phase.title, systemImage: pomodoro.phase.symbolName)
                    .font(.headline)
                    .foregroundStyle(pomodoro.phase.tint)
                Spacer()
                Text("Runde \(pomodoro.completedWorkSessions + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ring

            HStack(spacing: 10) {
                Button(action: pomodoro.toggle) {
                    Label(pomodoro.isRunning ? "Pause" : "Start",
                          systemImage: pomodoro.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(pomodoro.phase.tint)

                Button(action: pomodoro.reset) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .help("Zurücksetzen")

                Button(action: pomodoro.skip) {
                    Image(systemName: "forward.end.fill")
                }
                .buttonStyle(.bordered)
                .help("Phase überspringen")
            }
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 9)
            Circle()
                .trim(from: 0, to: pomodoro.remainingFraction)
                .stroke(pomodoro.phase.tint,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: pomodoro.remainingFraction)
            Text(formatClock(pomodoro.remaining))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 128, height: 128)
        .padding(.vertical, 2)
    }
}
