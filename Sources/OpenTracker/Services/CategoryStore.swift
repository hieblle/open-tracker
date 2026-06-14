import Foundation
import Observation

/// Maps app bundle identifiers to a productivity `AppCategory`.
///
/// Unknown apps fall back to a small preset table, and anything still unknown
/// is treated as `.neutral`. User choices are saved as overrides so the presets
/// are never destructive.
@Observable
final class CategoryStore {
    private var overrides: [String: AppCategory]

    @ObservationIgnored private let defaultsKey = "categoryOverrides"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([String: AppCategory].self, from: data) {
            overrides = decoded
        } else {
            overrides = [:]
        }
    }

    func category(for bundleId: String) -> AppCategory {
        overrides[bundleId] ?? Self.presets[bundleId] ?? .neutral
    }

    func setCategory(_ category: AppCategory, for bundleId: String) {
        overrides[bundleId] = category
        if let data = try? JSONEncoder().encode(overrides) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    /// Sensible defaults so the very first run isn't a wall of "neutral".
    static let presets: [String: AppCategory] = [
        // Productive
        "com.apple.dt.Xcode": .productive,
        "com.microsoft.VSCode": .productive,
        "com.todesktop.230313mzl4w4u92": .productive, // Cursor
        "com.apple.Terminal": .productive,
        "com.googlecode.iterm2": .productive,
        "com.jetbrains.intellij": .productive,
        "com.jetbrains.pycharm": .productive,
        "com.figma.Desktop": .productive,
        "notion.id": .productive,
        "md.obsidian": .productive,
        "com.apple.Notes": .productive,
        "com.linear": .productive,

        // Neutral (context dependent)
        "com.apple.Safari": .neutral,
        "com.google.Chrome": .neutral,
        "company.thebrowser.Browser": .neutral, // Arc
        "com.apple.mail": .neutral,
        "com.tinyspeck.slackmacgap": .neutral,
        "us.zoom.xos": .neutral,
        "com.apple.Music": .neutral,

        // Distracting
        "com.spotify.client": .distracting,
        "ru.keepcoder.Telegram": .distracting,
        "net.whatsapp.WhatsApp": .distracting,
        "com.hnc.Discord": .distracting,
        "com.apple.TV": .distracting,
        "com.apple.iChat": .distracting,
    ]
}
