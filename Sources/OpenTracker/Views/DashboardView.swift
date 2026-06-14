import SwiftUI

/// The main dashboard window: a detailed day view (with history navigation) and
/// a 7-day week overview.
struct DashboardView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories

    @State private var mode: Mode = .day
    @State private var dayOffset: Int = 0 // 0 = today, 1 = yesterday, …

    enum Mode: String, CaseIterable, Identifiable {
        case day = "Tag"
        case week = "Woche"
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
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 820, minHeight: 560)
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
                        .frame(width: 140)
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

/// Detailed breakdown for a single day.
struct DayDetailView: View {
    let date: Date
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories

    var body: some View {
        let day = usage.day(for: date)
        let productive = usage.seconds(for: .productive, in: day, using: categories)
        let neutral = usage.seconds(for: .neutral, in: day, using: categories)
        let distracting = usage.seconds(for: .distracting, in: day, using: categories)
        let rows = usage.activitySummaries(in: day, using: categories)
        let apps = rows.filter { $0.isApp }
        let websites = rows.filter { !$0.isApp }

        VStack(alignment: .leading, spacing: 20) {
            RatingSummaryCard(productive: productive, neutral: neutral, distracting: distracting)

            if productive + neutral + distracting == 0 {
                EmptyDayHint()
            } else {
                HStack(alignment: .top, spacing: 20) {
                    ActivityColumn(title: "Apps", icon: "macwindow", rows: apps)
                    ActivityColumn(
                        title: "Websites", icon: "globe", rows: websites,
                        emptyText: "Noch keine Web-Aktivität – im Browser surfen (Berechtigung nötig)."
                    )
                }
            }
        }
    }
}

/// 7-day overview with a stacked bar chart and aggregated totals.
struct WeekDetailView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories

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
        let week = usage.merged(days)
        let productive = usage.seconds(for: .productive, in: week, using: categories)
        let neutral = usage.seconds(for: .neutral, in: week, using: categories)
        let distracting = usage.seconds(for: .distracting, in: week, using: categories)
        let rows = usage.activitySummaries(in: week, using: categories)

        VStack(alignment: .leading, spacing: 20) {
            WeeklyBarChart(bars: bars)
            RatingSummaryCard(
                productive: productive, neutral: neutral, distracting: distracting,
                title: "Diese Woche (7 Tage)"
            )
            HStack(alignment: .top, spacing: 20) {
                ActivityColumn(title: "Top Apps", icon: "macwindow", rows: rows.filter { $0.isApp })
                ActivityColumn(title: "Top Websites", icon: "globe", rows: rows.filter { !$0.isApp })
            }
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
