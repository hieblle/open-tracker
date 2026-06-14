import SwiftUI

/// Whether a goal is a floor ("at least") or a ceiling/budget ("at most").
enum GoalDirection: String, Codable, Hashable {
    case atLeast
    case atMost
}

/// What a goal measures.
enum GoalMetric: Codable, Hashable {
    case workTime        // productive + neutral + distracting
    case focusTime       // productive
    case neutralTime
    case distractingTime
    case breakTime
    case project(String) // projectId
}

/// Picker-friendly metric kinds (project is parameterized separately).
enum GoalMetricKind: String, CaseIterable, Identifiable {
    case work, focus, neutral, distracting, breaks, project
    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: return "Arbeitszeit"
        case .focus: return "Fokuszeit"
        case .neutral: return "Neutrale Zeit"
        case .distracting: return "Ablenkung"
        case .breaks: return "Pausen"
        case .project: return "Projekt"
        }
    }

    func metric(projectId: String) -> GoalMetric {
        switch self {
        case .work: return .workTime
        case .focus: return .focusTime
        case .neutral: return .neutralTime
        case .distracting: return .distractingTime
        case .breaks: return .breakTime
        case .project: return .project(projectId)
        }
    }
}

/// A user goal: a daily target for some metric, in a given direction.
struct Goal: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var metric: GoalMetric
    var direction: GoalDirection
    var targetMinutes: Int
}

/// A one-click starting point for a goal.
struct GoalTemplate: Identifiable {
    let id: String
    let title: String
    let description: String
    let metric: GoalMetric
    let direction: GoalDirection
    let defaultMinutes: Int
}

/// A goal evaluated against a day's data.
struct GoalProgress: Identifiable {
    let goal: Goal
    let currentSeconds: Double

    var id: String { goal.id }
    var targetSeconds: Double { Double(goal.targetMinutes) * 60 }
    var fraction: Double { targetSeconds > 0 ? min(currentSeconds / targetSeconds, 1) : 0 }

    var isAchieved: Bool {
        switch goal.direction {
        case .atLeast: return currentSeconds >= targetSeconds
        case .atMost: return currentSeconds <= targetSeconds
        }
    }

    var color: Color {
        switch goal.direction {
        case .atLeast:
            return isAchieved ? .green : .blue
        case .atMost:
            if currentSeconds <= targetSeconds * 0.8 { return .green }
            if currentSeconds <= targetSeconds { return .orange }
            return .red
        }
    }

    var statusText: String {
        let current = formatDuration(currentSeconds)
        let target = formatDuration(targetSeconds)
        switch goal.direction {
        case .atLeast:
            return isAchieved ? "\(current) – erreicht ✓" : "\(current) / \(target)"
        case .atMost:
            return currentSeconds <= targetSeconds ? "\(current) / \(target)" : "\(current) – überschritten"
        }
    }
}
