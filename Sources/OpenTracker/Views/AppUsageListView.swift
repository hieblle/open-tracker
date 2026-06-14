import SwiftUI

/// Scrollable list of today's apps with per-row category control.
struct AppUsageListView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories

    var body: some View {
        let rows = usage.summaries(using: categories)

        VStack(alignment: .leading, spacing: 6) {
            Text("Apps").font(.headline)

            if rows.isEmpty {
                Text("Noch keine Aktivität erfasst.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(rows.prefix(12)) { row in
                            AppUsageRow(summary: row)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }
}

/// One app row: icon, name, time, and a colored dot that opens a category menu.
private struct AppUsageRow: View {
    let summary: AppUsageSummary
    @Environment(CategoryStore.self) private var categories

    var body: some View {
        HStack(spacing: 8) {
            AppIcon(bundleId: summary.bundleId)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(summary.name)
                    .lineLimit(1)
                Text(formatDuration(summary.seconds))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 6)

            Menu {
                ForEach(AppCategory.allCases) { category in
                    Button {
                        categories.setCategory(category, for: summary.bundleId)
                    } label: {
                        Label(category.title, systemImage: category.symbolName)
                    }
                }
            } label: {
                Circle()
                    .fill(summary.category.color)
                    .frame(width: 11, height: 11)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Kategorie: \(summary.category.title)")
        }
        .padding(.vertical, 2)
    }
}
