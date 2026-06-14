import Foundation

/// `m:ss` clock style, used for the live Pomodoro countdown.
func formatClock(_ interval: TimeInterval) -> String {
    let total = Int(max(0, interval.rounded()))
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%d:%02d", minutes, seconds)
}

/// Human-friendly duration, e.g. `2 h 13 min`, `7 min`, `45 s`.
func formatDuration(_ interval: TimeInterval) -> String {
    let total = Int(max(0, interval.rounded()))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60

    if hours > 0 { return "\(hours) h \(minutes) min" }
    if minutes > 0 { return "\(minutes) min" }
    return "\(seconds) s"
}
