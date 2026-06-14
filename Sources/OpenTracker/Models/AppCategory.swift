import SwiftUI

/// How a given application counts towards your focus.
enum AppCategory: String, Codable, CaseIterable, Identifiable {
    case productive
    case neutral
    case distracting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .productive: return "Produktiv"
        case .neutral: return "Neutral"
        case .distracting: return "Ablenkung"
        }
    }

    var symbolName: String {
        switch self {
        case .productive: return "checkmark.seal.fill"
        case .neutral: return "circle.dashed"
        case .distracting: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .productive: return .green
        case .neutral: return .gray
        case .distracting: return .orange
        }
    }
}
