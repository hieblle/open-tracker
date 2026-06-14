import SwiftUI

/// The main dashboard window: detailed day view (with history navigation),
/// a 7-day week overview, and a management tab for projects & categories.
struct DashboardView: View {
    @State private var mode: Mode = .day
    @State private var dayOffset: Int = 0 // 0 = today, 1 = yesterday, …

    enum Mode: String, CaseIterable, Identifiable {
        case day = "Tag"
        case week = "Woche"
        case manage = "Verwalten"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                Group {
                    switch mode {
                    case .day: DayDetailView(date: selectedDate)
                    case .week: WeekDetailView()
                    case .manage: ManagementView()
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 860, minHeight: 580)
    }

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text("Produktivität")
                .font(.title.bold())

            Spacer()

            if mode == .day {
                HStack(spacing: 6) {
                    Button { dayOffset += 1 } label: { Image(systemName: "chevron.left") }
                    Text(dayLabel)
                        .font(.subheadline)
                        .frame(width: 150)
                        .multilineTextAlignment(.center)
                    Button { if dayOffset > 0 { dayOffset -= 1 } } label: { Image(systemName: "chevron.right") }
                        .disabled(dayOffset == 0)
                }
                .buttonStyle(.borderless)
            }

            Picker("", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(20)
    }

    private var dayLabel: String {
        switch dayOffset {
        case 0: return "Heute"
        case 1: return "Gestern"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateFormat = "EEEE, d. MMM"
            return formatter.string(from: selectedDate)
        }
    }
}

/// Detailed breakdown + insights for a single day.
struct DayDetailView: View {
    let date: Date
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories
    @Environment(ProjectStore.self) private var projects

    var body: some View {
        let day = usage.day(for: date)
        let metrics = usage.metrics(in: day, using: categories)
        let rows = usage.activitySummaries(in: day, using: categories)
        let projectTotals = usage.projectTotals(in: day, using: projects)

        VStack(alignment: .leading, spacing: 20) {
            RatingSummaryCard(
                productive: metrics.focusSeconds,
                neutral: metrics.neutralSeconds,
                distracting: metrics.distractingSeconds
            )

            if metrics.activeSeconds == 0 {
                EmptyDayHint()
            } else {
                InsightsRow(metrics: metrics)

                if !day.segments.isEmpty {
                    TimelineStrip(segments: day.segments, categories: categories)
                }

                if !projectTotals.isEmpty {
                    ProjectBreakdownCard(totals: projectTotals)
                }

                HStack(alignment: .top, spacing: 20) {
                    ActivityColumn(title: "Apps", icon: "macwindow", rows: rows.filter { $0.isApp })
                    ActivityColumn(
                        title: "Websites", icon: "globe", rows: rows.filter { !$0.isApp },
                        emptyText: "Noch keine Web-Aktivität – im Browser surfen (Berechtigung nötig)."
                    )
                }
            }
        }
    }
}

/// 7-day overview with a stacked bar chart, aggregated insights and totals.
struct WeekDetailView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories
    @Environment(ProjectStore.self) private var projects

    var body: some View {
        let days = usage.recentDays(7)
        let bars = days.map { day in
            DayBar(
                label: Self.weekdayLabel(day.dateKey),
                productive: usage.seconds(for: .productive, in: day, using: categories),
                neutral: usage.seconds(for: .neutral, in: day, using: categories),
                distracting: usage.seconds(for: .distracting, in: day, using: categories)
            )
        }
        let perDayMetrics = days.map { usage.metrics(in: $0, using: categories) }
        let week = usage.merged(days)
        let weekMetrics = usage.metrics(in: week, using: categories)
        let rows = usage.activitySummaries(in: week, using: categories)
        let projectTotals = usage.projectTotals(in: week, using: projects)

        VStack(alignment: .leading, spacing: 20) {
            WeeklyBarChart(bars: bars)
            weekInsights(week: weekMetrics, perDay: perDayMetrics)
            RatingSummaryCard(
                productive: weekMetrics.focusSeconds,
                neutral: weekMetrics.neutralSeconds,
                distracting: weekMetrics.distractingSeconds,
                title: "Diese Woche (7 Tage)"
            )
            if !projectTotals.isEmpty {
                ProjectBreakdownCard(totals: projectTotals, title: "Projekte (Woche)")
            }
            HStack(alignment: .top, spacing: 20) {
                ActivityColumn(title: "Top Apps", icon: "macwindow", rows: rows.filter { $0.isApp })
                ActivityColumn(title: "Top Websites", icon: "globe", rows: rows.filter { !$0.isApp })
            }
        }
    }

    private func weekInsights(week: DayMetrics, perDay: [DayMetrics]) -> some View {
        let activeDays = max(perDay.filter { $0.activeSeconds > 0 }.count, 1)
        return HStack(spacing: 14) {
            StatTile(title: "Fokuszeit gesamt", value: formatDuration(week.focusSeconds),
                     subtitle: "Ø \(formatDuration(week.focusSeconds / Double(activeDays))) / aktivem Tag",
                     systemImage: "target", tint: AppCategory.productive.color)
            StatTile(title: "Kontextwechsel", value: "\(week.contextSwitches)",
                     subtitle: "diese Woche", systemImage: "arrow.left.arrow.right", tint: .purple)
            StatTile(title: "Pausen", value: "\(week.breakCount)",
                     subtitle: week.breakSeconds > 0 ? formatDuration(week.breakSeconds) : "—",
                     systemImage: "cup.and.saucer", tint: .blue)
            StatTile(title: "Aktive Zeit", value: formatDuration(week.activeSeconds),
                     subtitle: "Ø \(formatDuration(week.activeSeconds / Double(activeDays))) / Tag",
                     systemImage: "clock", tint: .teal)
        }
    }

    static func weekdayLabel(_ dateKey: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateKey) else { return dateKey }
        let output = DateFormatter()
        output.locale = Locale(identifier: "de_DE")
        output.dateFormat = "EE"
        return output.string(from: date)
    }
}
