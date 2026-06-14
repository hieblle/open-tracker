import SwiftUI

/// A thin progress bar (single value, 0…1).
struct ProgressBar: View {
    let fraction: Double
    var color: Color = .blue
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(fraction, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

/// Card listing goal progress for a day.
struct GoalsCard: View {
    let progress: [GoalProgress]
    var title: String = "Ziele heute"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                let achieved = progress.filter { $0.isAchieved }.count
                Text("\(achieved)/\(progress.count) erreicht")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(progress) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: item.isAchieved ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.color)
                        Text(item.goal.title).font(.subheadline)
                        Spacer()
                        Text(item.statusText).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                    }
                    ProgressBar(fraction: item.fraction, color: item.color)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }
}
