import SwiftUI
import AppKit

/// The dropdown panel shown when the menu bar item is clicked.
struct PanelView: View {
    @Environment(ActivityTracker.self) private var tracker
    @State private var showingSettings = false

    var body: some View {
        Group {
            if showingSettings {
                SettingsView(onClose: { showingSettings = false })
            } else {
                main
            }
        }
        .frame(width: 340)
        .padding(14)
    }

    private var main: some View {
        VStack(alignment: .leading, spacing: 14) {
            PomodoroView()
            Divider()
            TodaySummaryView()
            Divider()
            AppUsageListView()
            footer
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Einstellungen")

            Spacer(minLength: 8)

            Label {
                Text(tracker.isIdle ? "Inaktiv" : tracker.currentAppName)
                    .lineLimit(1)
            } icon: {
                Circle()
                    .fill(tracker.isIdle ? Color.secondary : Color.green)
                    .frame(width: 7, height: 7)
            }
            .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .help("OpenTracker beenden")
        }
        .font(.caption)
        .padding(.top, 2)
    }
}
