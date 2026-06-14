import SwiftUI

/// Time-per-project breakdown card with proportional bars.
struct ProjectBreakdownCard: View {
    let totals: [ProjectTotal]
    var title: String = "Projekte"

    var body: some View {
        let sum = max(totals.reduce(0) { $0 + $1.seconds }, 1)
        let maxSeconds = max(totals.map { $0.seconds }.max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            ForEach(totals.prefix(12)) { item in
                HStack(spacing: 10) {
                    Text("\(Int((item.seconds / sum * 100).rounded()))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 38, alignment: .trailing)
                        .foregroundStyle(.secondary)
                    Circle().fill(item.project.color).frame(width: 9, height: 9)
                    Text(item.project.name).lineLimit(1)
                    Spacer(minLength: 12)
                    Capsule()
                        .fill(item.project.color.opacity(0.45))
                        .frame(width: 120 * CGFloat(item.seconds / maxSeconds), height: 6)
                    Text(formatDuration(item.seconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 82, alignment: .trailing)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }
}
