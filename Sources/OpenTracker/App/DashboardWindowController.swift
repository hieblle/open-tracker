import AppKit
import SwiftUI

/// Opens the dashboard in a real resizable window on demand.
///
/// We manage the window via AppKit (rather than a SwiftUI `Window` scene) so it
/// only appears when the user asks for it — and we flip the app to a regular
/// (Dock-visible) app while it's open, back to a menu-bar agent when it closes.
@MainActor
final class DashboardWindowController {
    static let shared = DashboardWindowController()

    private var window: NSWindow?
    private var delegate: WindowDelegate?

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let model = AppModel.shared
        let root = DashboardView()
            .environment(model.usage)
            .environment(model.categories)
            .environment(model.projects)
            .environment(model.goals)
            .environmentObject(model.settings)

        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.title = "OpenTracker"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 940, height: 720))
        window.center()
        window.isReleasedWhenClosed = false

        let delegate = WindowDelegate { [weak self] in
            self?.window = nil
            self?.delegate = nil
            // Back to menu-bar-only once the dashboard is gone.
            NSApp.setActivationPolicy(.accessory)
        }
        window.delegate = delegate

        self.delegate = delegate
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    private final class WindowDelegate: NSObject, NSWindowDelegate {
        let onClose: () -> Void
        init(onClose: @escaping () -> Void) { self.onClose = onClose }
        func windowWillClose(_ notification: Notification) { onClose() }
    }
}
