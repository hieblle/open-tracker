import Foundation
import Observation

/// Maps apps *and* website domains to a productivity `AppCategory`.
///
/// Lookups fall back to preset tables, then to `.neutral`. User choices are
/// stored as overrides so presets are never destructive.
@Observable
final class CategoryStore {
    private var appOverrides: [String: AppCategory]
    private var domainOverrides: [String: AppCategory]

    @ObservationIgnored private let appKey = "categoryOverrides"
    @ObservationIgnored private let domainKey = "domainCategoryOverrides"

    init() {
        let ud = UserDefaults.standard
        appOverrides = ud.data(forKey: "categoryOverrides")
            .flatMap { try? JSONDecoder().decode([String: AppCategory].self, from: $0) } ?? [:]
        domainOverrides = ud.data(forKey: "domainCategoryOverrides")
            .flatMap { try? JSONDecoder().decode([String: AppCategory].self, from: $0) } ?? [:]
    }

    // MARK: Lookups

    func category(forApp bundleId: String) -> AppCategory {
        appOverrides[bundleId] ?? Self.appPresets[bundleId] ?? .neutral
    }

    func category(forDomain domain: String) -> AppCategory {
        domainOverrides[domain] ?? Self.presetCategory(forDomain: domain) ?? .neutral
    }

    // MARK: Mutations

    func setCategory(_ category: AppCategory, forApp bundleId: String) {
        appOverrides[bundleId] = category
        persist(appOverrides, forKey: appKey)
    }

    func setCategory(_ category: AppCategory, forDomain domain: String) {
        domainOverrides[domain] = category
        persist(domainOverrides, forKey: domainKey)
    }

    func setCategory(_ category: AppCategory, for summary: ActivitySummary) {
        switch summary.kind {
        case .app(let bundleId): setCategory(category, forApp: bundleId)
        case .website(let domain): setCategory(category, forDomain: domain)
        }
    }

    private func persist(_ map: [String: AppCategory], forKey key: String) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Presets

    /// Match a domain against presets, trying the exact host first and then
    /// progressively shorter suffixes (so `mail.google.com` and `gist.github.com`
    /// resolve correctly).
    private static func presetCategory(forDomain domain: String) -> AppCategory? {
        if let exact = domainPresets[domain] { return exact }
        let parts = domain.split(separator: ".")
        if parts.count >= 3 {
            let suffix3 = parts.suffix(3).joined(separator: ".")
            if let match = domainPresets[suffix3] { return match }
        }
        if parts.count >= 2 {
            let suffix2 = parts.suffix(2).joined(separator: ".")
            if let match = domainPresets[suffix2] { return match }
        }
        return nil
    }

    static let appPresets: [String: AppCategory] = [
        // Productive
        "com.apple.dt.Xcode": .productive,
        "com.microsoft.VSCode": .productive,
        "com.todesktop.230313mzl4w4u92": .productive, // Cursor
        "com.apple.Terminal": .productive,
        "com.googlecode.iterm2": .productive,
        "com.jetbrains.intellij": .productive,
        "com.jetbrains.pycharm": .productive,
        "com.figma.Desktop": .productive,
        "com.bohemiancoding.sketch3": .productive,
        "notion.id": .productive,
        "md.obsidian": .productive,
        "com.apple.Notes": .productive,
        // Neutral
        "com.apple.mail": .neutral,
        "com.tinyspeck.slackmacgap": .neutral,
        "us.zoom.xos": .neutral,
        "com.microsoft.teams2": .neutral,
        "com.apple.iCal": .neutral,
        "com.apple.Music": .neutral,
        // Browsers: time is tracked per-domain, so the app itself stays neutral
        "com.apple.Safari": .neutral,
        "com.google.Chrome": .neutral,
        "company.thebrowser.Browser": .neutral,
        "org.mozilla.firefox": .neutral,
        "com.brave.Browser": .neutral,
        "com.microsoft.edgemac": .neutral,
        // Distracting
        "com.spotify.client": .distracting,
        "ru.keepcoder.Telegram": .distracting,
        "net.whatsapp.WhatsApp": .distracting,
        "com.hnc.Discord": .distracting,
        "com.apple.TV": .distracting,
    ]

    static let domainPresets: [String: AppCategory] = [
        // Productive
        "github.com": .productive, "gitlab.com": .productive, "stackoverflow.com": .productive,
        "developer.apple.com": .productive, "developer.mozilla.org": .productive,
        "claude.ai": .productive, "chatgpt.com": .productive, "chat.openai.com": .productive,
        "figma.com": .productive, "docs.google.com": .productive, "notion.so": .productive,
        "wikipedia.org": .productive, "coursera.org": .productive, "udemy.com": .productive,
        // Neutral
        "mail.google.com": .neutral, "outlook.office.com": .neutral,
        "meet.google.com": .neutral, "zoom.us": .neutral, "google.com": .neutral,
        "linkedin.com": .neutral, "calendar.google.com": .neutral,
        // Distracting
        "youtube.com": .distracting, "netflix.com": .distracting, "twitch.tv": .distracting,
        "twitter.com": .distracting, "x.com": .distracting, "instagram.com": .distracting,
        "facebook.com": .distracting, "reddit.com": .distracting, "tiktok.com": .distracting,
        "nytimes.com": .distracting, "orf.at": .distracting, "derstandard.at": .distracting,
        "amazon.com": .distracting, "amazon.de": .distracting, "ebay.com": .distracting,
    ]
}
