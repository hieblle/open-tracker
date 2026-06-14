import SwiftUI

/// One day's stacked column in the weekly chart.
struct DayBar: Identifiable {
    let id = UUID()
    let label: String
    let productive: Double
    let neutral: Double
    let distracting: Double

    var total: Double { productive + neutral + distracting }
}

/// A simple stacked-bar history chart, drawn with plain SwiftUI (no dependencies).
struct WeeklyBarChart: View {
    let bars: [DayBar]
    private let chartHeight: CGFloat = 200

    var body: some View {
        let maxSeconds = max(bars.map { $0.total }.max() ?? 1, 1)
        let maxHours = maxSeconds / 3600

        VStack(alignment: .leading, spacing: 12) {
            Text("Verlauf – 7 Tage").font(.headline)

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .trailing) {
                    Text(String(format: "%.0f h", maxHours.rounded(.up)))
                    Spacer()
                    Text("0 h")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: chartHeight)
                .padding(.trailing, 8)

                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(bars) { bar in
                        VStack(spacing: 6) {
                            column(for: bar, maxSeconds: maxSeconds)
                            Text(bar.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            legend
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }

    private func column(for bar: DayBar, maxSeconds: Double) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            AppCategory.distracting.color.frame(height: height(bar.distracting, maxSeconds))
            AppCategory.neutral.color.frame(height: height(bar.neutral, maxSeconds))
            AppCategory.productive.color.frame(height: height(bar.productive, maxSeconds))
        }
        .frame(height: chartHeight)
        .frame(maxWidth: 44)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func height(_ seconds: Double, _ maxSeconds: Double) -> CGFloat {
        chartHeight * CGFloat(seconds / maxSeconds)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(AppCategory.allCases) { rating in
                HStack(spacing: 5) {
                    Circle().fill(rating.color).frame(width: 8, height: 8)
                    Text(rating.title).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}
