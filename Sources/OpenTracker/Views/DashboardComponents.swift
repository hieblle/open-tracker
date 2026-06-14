import SwiftUI

/// Card with the Produktiv/Neutral/Ablenkung split, percentages and a bar.
struct RatingSummaryCard: View {
    let productive: Double
    let neutral: Double
    let distracting: Double
    var title: String = "Heute"

    var body: some View {
        let total = productive + neutral + distracting
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline)
                Spacer()
                Text(total > 0 ? "Gesamt \(formatDuration(total))" : "Keine Aktivität")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 28) {
                RatingStat(rating: .productive, seconds: productive, total: total)
                RatingStat(rating: .neutral, seconds: neutral, total: total)
                RatingStat(rating: .distracting, seconds: distracting, total: total)
            }

            ProportionBar(segments: [
                .init(value: productive, color: AppCategory.productive.color),
                .init(value: neutral, color: AppCategory.neutral.color),
                .init(value: distracting, color: AppCategory.distracting.color),
            ], height: 14)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }
}

/// A single big percentage + duration for one rating.
struct RatingStat: View {
    let rating: AppCategory
    let seconds: Double
    let total: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle().fill(rating.color).frame(width: 9, height: 9)
                Text(rating.title).font(.caption).foregroundStyle(.secondary)
            }
            Text(total > 0 ? "\(Int((seconds / total * 100).rounded()))%" : "—")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(formatDuration(seconds))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

/// A titled column listing activities (apps or websites).
struct ActivityColumn: View {
    let title: String
    var icon: String = "macwindow"
    let rows: [ActivitySummary]
    var emptyText: String = "—"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.headline)
            if rows.isEmpty {
                Text(emptyText).font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(rows.prefix(15)) { row in
                    ActivityRow(summary: row)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Friendly placeholder for a day with no tracked activity.
struct EmptyDayHint: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Für diesen Tag wurde noch keine Aktivität erfasst.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
