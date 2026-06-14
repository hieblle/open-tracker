import SwiftUI

/// Meta-analysis card centered on **interruptions of focus phases** — the thing
/// that actually matters: when does sustained productive work get broken, and
/// by what. Raw context switches are shown only as a small secondary line,
/// because switching between productive tools is not an interruption.
struct FocusQualitySection: View {
    let analysis: FocusAnalysis
    var phaseMinutes: Int = 15

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fokus-Unterbrechungen").font(.headline)
            Text("Wie oft deine Produktivphasen (≥ \(phaseMinutes) min am Stück) unterbrochen werden. Wechsel zwischen produktiven Tätigkeiten zählen bewusst nicht.")
                .font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 14) {
                StatTile(
                    title: "Unterbrechungen",
                    value: "\(analysis.focusInterruptions)",
                    subtitle: "von \(analysis.focusPhaseCount) Fokusphasen",
                    systemImage: "bolt.horizontal.circle",
                    tint: .orange
                )
                StatTile(
                    title: "pro Fokus-Stunde",
                    value: analysis.totalFocusSeconds > 0 ? String(format: "%.1f", analysis.interruptionsPerFocusHour) : "—",
                    subtitle: "wie oft gestört",
                    systemImage: "speedometer",
                    tint: .purple
                )
                StatTile(
                    title: "Ø ungestörte Phase",
                    value: analysis.averageFocusBlockSeconds > 0 ? formatDuration(analysis.averageFocusBlockSeconds) : "—",
                    subtitle: "\(analysis.focusBlockCount) Phasen gesamt",
                    systemImage: "square.stack",
                    tint: AppCategory.productive.color
                )
                StatTile(
                    title: "Tiefer Fokus",
                    value: analysis.deepFocusSeconds > 0 ? formatDuration(analysis.deepFocusSeconds) : "—",
                    subtitle: "in Phasen ≥ 15 min",
                    systemImage: "bolt.fill",
                    tint: AppCategory.productive.color
                )
            }

            if analysis.focusInterruptions > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wodurch wirst du unterbrochen?")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 20) {
                        causeItem(.distraction, analysis.interruptionsByDistraction)
                        causeItem(.neutral, analysis.interruptionsByNeutral)
                        causeItem(.pause, analysis.interruptionsByBreak)
                    }
                }
            }

            if analysis.interrupters.isEmpty {
                Text("Keine unterbrochenen Fokusphasen erkannt – stark! 🎯")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Häufigste Unterbrecher").font(.subheadline.bold())
                    ForEach(analysis.interrupters.prefix(6)) { interrupter in
                        HStack(spacing: 8) {
                            Circle().fill(interrupter.kind.color).frame(width: 8, height: 8)
                            Text(interrupter.label).lineLimit(1)
                            Text("· \(interrupter.kind.title)")
                                .font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(interrupter.count)×")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider().opacity(0.4)
            Text("Kontextwechsel gesamt: \(analysis.appSwitches) App · \(analysis.tabSwitches) Tab · Fragmentierung \(Int((analysis.fragmentation * 100).rounded()))%")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
    }

    private func causeItem(_ kind: InterruptionKind, _ count: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(kind.color).frame(width: 9, height: 9)
            Text(kind.title).font(.caption).foregroundStyle(.secondary)
            Text("\(count)").font(.caption.bold().monospacedDigit())
        }
    }
}
