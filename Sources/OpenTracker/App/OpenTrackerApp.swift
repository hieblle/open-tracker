import SwiftUI

@main
struct OpenTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .environmentObject(model.settings)
                .environment(model.categories)
                .environment(model.usage)
                .environment(model.pomodoro)
                .environment(model.tracker)
        } label: {
            MenuBarLabel()
                .environment(model.pomodoro)
        }
        .menuBarExtraStyle(.window)
    }
}
