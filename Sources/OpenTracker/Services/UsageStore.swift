import AppKit
import Observation

/// Owns "today's" usage aggregate and persists it to disk.
///
/// Data lives in `~/Library/Application Support/OpenTracker/usage-YYYY-MM-DD.json`.
/// Writes are throttled and also flushed on quit so we never thrash the disk.
@Observable
final class UsageStore {
    private(set) var today: DayUsage

    @ObservationIgnored private let directory: URL
    @ObservationIgnored private var currentDateKey: String
    @ObservationIgnored private var lastSave: Date = .distantPast

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("OpenTracker", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.directory = dir

        let key = Self.dateKey(for: Date())
        self.currentDateKey = key
        self.today = Self.load(dateKey: key, in: dir) ?? DayUsage(dateKey: key)

        // Make sure we don't lose the last few seconds when the app quits.
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.save()
        }
    }

    func addActiveTime(seconds: TimeInterval, bundleId: String, name: String) {
        rolloverIfNeeded()
        today.add(seconds: seconds, bundleId: bundleId, name: name)
        if Date().timeIntervalSince(lastSave) > 20 {
            save()
        }
    }

    /// Per-app rows for today, sorted by time spent (descending).
    func summaries(using categories: CategoryStore) -> [AppUsageSummary] {
        today.secondsByApp
            .map { bundleId, seconds in
                AppUsageSummary(
                    bundleId: bundleId,
                    name: today.namesByApp[bundleId] ?? bundleId,
                    seconds: seconds,
                    category: categories.category(for: bundleId)
                )
            }
            .sorted { $0.seconds > $1.seconds }
    }

    /// Total seconds today belonging to a given category.
    func seconds(for category: AppCategory, using categories: CategoryStore) -> TimeInterval {
        today.secondsByApp.reduce(0) { partial, entry in
            categories.category(for: entry.key) == category ? partial + entry.value : partial
        }
    }

    func save() {
        lastSave = Date()
        let url = directory.appendingPathComponent("usage-\(today.dateKey).json")
        if let data = try? JSONEncoder().encode(today) {
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Roll over to a fresh aggregate when the local calendar day changes.
    private func rolloverIfNeeded() {
        let key = Self.dateKey(for: Date())
        guard key != currentDateKey else { return }
        save() // persist the day that just ended
        currentDateKey = key
        today = Self.load(dateKey: key, in: directory) ?? DayUsage(dateKey: key)
    }

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func load(dateKey: String, in dir: URL) -> DayUsage? {
        let url = dir.appendingPathComponent("usage-\(dateKey).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DayUsage.self, from: data)
    }
}
