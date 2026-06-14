import SwiftUI

/// A user-created project that groups apps and websites together.
struct Project: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var colorIndex: Int

    var color: Color {
        let count = Project.palette.count
        return Project.palette[((colorIndex % count) + count) % count]
    }

    static let palette: [Color] = [
        .blue, .purple, .pink, .orange, .green, .teal, .indigo, .mint, .red, .cyan,
    ]
}

/// Time aggregated for a single project (for breakdown cards).
struct ProjectTotal: Identifiable {
    let project: Project
    let seconds: Double
    var id: String { project.id }
}
