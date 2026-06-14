import Foundation
import AppKit

/// Reads the active tab's domain from supported browsers via AppleScript.
///
/// Requires Automation (Apple Events) permission, declared through
/// `NSAppleEventsUsageDescription` in Info.plist. The first query to each
/// browser triggers a one-time macOS permission prompt; if denied, we simply
/// fall back to attributing the time to the browser app itself.
enum BrowserScripting {
    enum Family { case safari, chromium, firefox }

    /// Bundle ids we know how to script → (AppleScript app name, family).
    static let browsers: [String: (name: String, family: Family)] = [
        "com.apple.Safari": ("Safari", .safari),
        "com.apple.SafariTechnologyPreview": ("Safari Technology Preview", .safari),
        "com.google.Chrome": ("Google Chrome", .chromium),
        "com.google.Chrome.canary": ("Google Chrome Canary", .chromium),
        "com.brave.Browser": ("Brave Browser", .chromium),
        "com.microsoft.edgemac": ("Microsoft Edge", .chromium),
        "com.vivaldi.Vivaldi": ("Vivaldi", .chromium),
        "company.thebrowser.Browser": ("Arc", .chromium),
        "org.mozilla.firefox": ("Firefox", .firefox),
    ]

    static func isBrowser(_ bundleId: String?) -> Bool {
        guard let bundleId else { return false }
        return browsers[bundleId] != nil
    }

    /// The active tab's domain (e.g. `github.com`) or nil.
    ///
    /// Apple Events can block, so call this off the main thread.
    static func activeDomain(forBundleId bundleId: String) -> String? {
        guard let browser = browsers[bundleId] else { return nil }
        // Firefox has no usable URL scripting; fall back to app-level tracking.
        guard browser.family != .firefox else { return nil }

        let tabReference = browser.family == .safari ? "current tab" : "active tab"
        let source = "tell application \"\(browser.name)\" to get URL of \(tabReference) of front window"

        guard let urlString = runAppleScript(source) else { return nil }
        return domain(from: urlString)
    }

    private static func runAppleScript(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }

    /// Reduce a full URL to a bare domain, dropping a leading `www.`.
    static func domain(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let host = components.host, !host.isEmpty else {
            return nil
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
