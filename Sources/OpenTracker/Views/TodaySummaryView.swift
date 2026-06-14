import SwiftUI

/// Today's headline: focus score, the productive/neutral/distracting split,
/// and total tracked time.
struct TodaySummaryView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories

    var body: some View {
        let productive = usage.seconds(for: .productive, using: categories)
        let neutral = usage.seconds(for: .neutral, using: categories)
        let distracting = usage.seconds(for: .distracting, using: categories)
        let total = productive + neutral + distracting

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Heute").font(.headline)
                Spacer()
                Text(total > 0 ? formatDuration(total) : "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(total > 0 ? "\(Int((productive / total * 100).rounded()))%" : "—")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppCategory.productive.color)
                Text("Fokus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProportionBar(segments: [
                .init(value: productive, color: AppCategory.productive.color),
                .init(value: neutral, color: AppCategory.neutral.color),
                .init(value: distracting, color: AppCategory.distracting.color),
            ])

            HStack(spacing: 12) {
                legendItem(.productive, seconds: productive)
                legendItem(.neutral, seconds: neutral)
                legendItem(.distracting, seconds: distracting)
            }
        }
    }

    private func legendItem(_ category: AppCategory, seconds: TimeInterval) -> some View {
        HStack(spacing: 5) {
            Circle().fill(category.color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(category.title).font(.caption2).foregroundStyle(.secondary)
                Text(seconds > 0 ? formatDuration(seconds) : "—")
                    .font(.caption2).monospacedDigit()
            }
        }
    }
}
