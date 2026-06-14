import SwiftUI

/// A single headline statistic.
struct StatTile: View {
    let title: String
    let value: String
    var subtitle: String?
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .monospacedDigit()
            Text(subtitle ?? " ")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
        .overlay(alignment: .topTrailing) {
            Circle().fill(tint).frame(width: 6, height: 6).padding(10)
        }
    }
}

/// The four headline insights for a day: focus, switches, breaks, longest run.
struct InsightsRow: View {
    let metrics: DayMetrics

    var body: some View {
        HStack(spacing: 14) {
            StatTile(
                title: "Fokuszeit",
                value: formatDuration(metrics.focusSeconds),
                subtitle: metrics.focusSessionCount > 0
                    ? "\(metrics.focusSessionCount) Session(s) ≥ 15 min" : "noch keine lange Session",
                systemImage: "target",
                tint: AppCategory.productive.color
            )
            StatTile(
                title: "Kontextwechsel",
                value: "\(metrics.contextSwitches)",
                subtitle: metrics.activeSeconds > 0 ? String(format: "%.0f / Std.", metrics.switchesPerHour) : nil,
                systemImage: "arrow.left.arrow.right",
                tint: .purple
            )
            StatTile(
                title: "Pausen",
                value: "\(metrics.breakCount)",
                subtitle: metrics.breakSeconds > 0 ? formatDuration(metrics.breakSeconds) : "keine ≥ 2 min",
                systemImage: "cup.and.saucer",
                tint: .blue
            )
            StatTile(
                title: "Längste Fokus-Phase",
                value: metrics.longestFocusSeconds > 0 ? formatDuration(metrics.longestFocusSeconds) : "—",
                subtitle: "am Stück produktiv",
                systemImage: "bolt.fill",
                tint: AppCategory.productive.color
            )
        }
    }
}

/// A horizontal, time-ordered strip of the day — colored by rating, with breaks.
/// Makes context switching and breaks visible at a glance.
struct TimelineStrip: View {
    let segments: [ActivitySegment]
    let categories: CategoryStore

    var body: some View {
        let total = max(segments.reduce(0) { $0 + $1.seconds }, 1)
        VStack(alignment: .leading, spacing: 8) {
            Text("Tagesverlauf").font(.headline)
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        color(for: segment)
                            .frame(width: geo.size.width * CGFloat(segment.seconds / total))
                    }
                }
            }
            .frame(height: 18)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.12)))

            HStack(spacing: 16) {
                ForEach(AppCategory.allCases) { rating in
                    legendDot(rating.color, rating.title)
                }
                legendDot(Self.breakColor, "Pause")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }

    private static let breakColor = Color.blue.opacity(0.3)

    private func color(for segment: ActivitySegment) -> Color {
        switch segment.kind {
        case .idle: return Self.breakColor
        case .app(let bundleId, _): return categories.category(forApp: bundleId).color
        case .website(let domain): return categories.category(forDomain: domain).color
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
