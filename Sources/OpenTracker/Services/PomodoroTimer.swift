import AppKit
import Observation

/// A small Pomodoro state machine: Fokus → (kurze | lange) Pause → Fokus …
///
/// The countdown is driven off an absolute `endDate` rather than by decrementing
/// a counter, so it stays correct even if a tick is delayed.
@Observable
final class PomodoroTimer {
    private(set) var phase: PomodoroPhase = .work
    private(set) var isRunning: Bool = false
    private(set) var remaining: TimeInterval
    private(set) var completedWorkSessions: Int = 0

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var endDate: Date?

    init(settings: AppSettings) {
        self.settings = settings
        self.remaining = TimeInterval(settings.workMinutes * 60)
    }

    var totalForCurrentPhase: TimeInterval {
        switch phase {
        case .work: return TimeInterval(settings.workMinutes * 60)
        case .shortBreak: return TimeInterval(settings.shortBreakMinutes * 60)
        case .longBreak: return TimeInterval(settings.longBreakMinutes * 60)
        }
    }

    /// Fraction of the phase still remaining (1 → full, 0 → done).
    var remainingFraction: Double {
        let total = totalForCurrentPhase
        guard total > 0 else { return 0 }
        return min(max(remaining / total, 0), 1)
    }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        endDate = Date().addingTimeInterval(remaining)
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        if let endDate { remaining = max(0, endDate.timeIntervalSinceNow) }
        endDate = nil
    }

    func reset() {
        pause()
        remaining = totalForCurrentPhase
    }

    /// Jump to the next phase without waiting for the timer to run out.
    func skip() { advancePhase(announce: false) }

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            advancePhase(announce: true)
        }
    }

    private func advancePhase(announce: Bool) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endDate = nil

        if announce { announceEnd(of: phase) }

        switch phase {
        case .work:
            completedWorkSessions += 1
            let cycle = max(1, settings.pomodorosUntilLongBreak)
            phase = (completedWorkSessions % cycle == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .work
        }
        remaining = totalForCurrentPhase
    }

    private func announceEnd(of phase: PomodoroPhase) {
        NSSound(named: "Glass")?.play()
        Notifier.shared.notifyPhaseEnded(phase)
    }
}
