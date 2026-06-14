import SwiftUI

/// Meta-analysis card: fragmentation, deep vs scattered focus, switch types and
/// the most frequent flow interrupters.
struct FocusQualitySection: View {
    let analysis: FocusAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fokus-Qualität").font(.headline)

            HStack(spacing: 14) {
                StatTile(
                    title: "Fragmentierung",
                    value: "\(Int((analysis.fragmentation * 100).rounded()))%",
                    subtitle: fragmentationLabel,
                    systemImage: "puzzlepiece",
                    tint: fragmentationColor
                )
                StatTile(
                    title: "Ø Fokus-Block",
                    value: analysis.averageFocusBlockSeconds > 0 ? formatDuration(analysis.averageFocusBlockSeconds) : "—",
                    subtitle: "\(analysis.focusBlockCount) Block/Blöcke",
                    systemImage: "square.stack",
                    tint: AppCategory.productive.color
                )
                StatTile(
                    title: "App-Wechsel",
                    value: "\(analysis.appSwitches)",
                    subtitle: "zwischen Apps",
                    systemImage: "macwindow.on.rectangle",
                    tint: .purple
                )
                StatTile(
                    title: "Tab-Wechsel",
                    value: "\(analysis.tabSwitches)",
                    subtitle: "zwischen Websites",
                    systemImage: "square.on.square",
                    tint: .indigo
                )
            }

            if analysis.totalFocusSeconds > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Tiefer Fokus (≥ 15 min) vs. zerstückelt")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(formatDuration(analysis.deepFocusSeconds)) · \(formatDuration(analysis.scatteredFocusSeconds))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    ProportionBar(segments: [
                        .init(value: analysis.deepFocusSeconds, color: AppCategory.productive.color),
                        .init(value: analysis.scatteredFocusSeconds, color: AppCategory.productive.color.opacity(0.35)),
                    ], height: 12)
                }
            }

            if analysis.interrupters.isEmpty {
                Text("Keine unterbrochenen Fokus-Phasen erkannt – stark! 🎯")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Häufigste Flow-Unterbrecher").font(.subheadline.bold())
                    ForEach(analysis.interrupters.prefix(6)) { interrupter in
                        HStack {
                            Text(interrupter.label).lineLimit(1)
                            Spacer()
                            Text("\(interrupter.count)×")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }

    private var fragmentationLabel: String {
        switch analysis.fragmentation {
        case ..<0.25: return "sehr fokussiert"
        case ..<0.5: return "okay"
        case ..<0.75: return "eher zerstückelt"
        default: return "stark zerstückelt"
        }
    }

    private var fragmentationColor: Color {
        if analysis.fragmentation < 0.4 { return AppCategory.productive.color }
        if analysis.fragmentation < 0.7 { return .orange }
        return AppCategory.distracting.color
    }
}
