import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar agent: no Dock icon, no app-switcher entry.
        NSApp.setActivationPolicy(.accessory)
        // Start background tracking exactly once.
        AppModel.shared.start()
    }
}
