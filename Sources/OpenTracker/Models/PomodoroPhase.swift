import SwiftUI

/// The three phases of a Pomodoro cycle.
enum PomodoroPhase {
    case work
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .work: return "Fokus"
        case .shortBreak: return "Kurze Pause"
        case .longBreak: return "Lange Pause"
        }
    }

    var symbolName: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "figure.walk"
        }
    }

    var tint: Color {
        switch self {
        case .work: return .pink
        case .shortBreak: return .teal
        case .longBreak: return .indigo
        }
    }
}
