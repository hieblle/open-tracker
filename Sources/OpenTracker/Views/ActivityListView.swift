import SwiftUI
import AppKit

/// A list of activities (apps and websites) with per-row category control.
struct ActivityListView: View {
    let title: String
    let rows: [ActivitySummary]
    var limit: Int = 8
    var emptyText: String = "Noch keine Aktivität erfasst."

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            if rows.isEmpty {
                Text(emptyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(rows.prefix(limit)) { row in
                    ActivityRow(summary: row)
                }
            }
        }
    }
}

/// One activity row: icon, name, time, and a colored dot opening a category menu.
struct ActivityRow: View {
    let summary: ActivitySummary
    @Environment(CategoryStore.self) private var categories

    var body: some View {
        HStack(spacing: 8) {
            ActivityIcon(kind: summary.kind)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(summary.name).lineLimit(1)
                Text(formatDuration(summary.seconds))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 6)

            Menu {
                ForEach(AppCategory.allCases) { category in
                    Button {
                        categories.setCategory(category, for: summary)
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

/// App icon for apps, globe glyph for websites.
struct ActivityIcon: View {
    let kind: ActivitySummary.Kind

    var body: some View {
        switch kind {
        case .app(let bundleId):
            if let image = AppIcon.icon(for: bundleId) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
            }
        case .website:
            Image(systemName: "globe")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
    }
}
