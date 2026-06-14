import AppKit
import Observation

/// Owns "today's" usage aggregate (apps + website domains) and persists it.
///
/// Data lives in `~/Library/Application Support/OpenTracker/usage-YYYY-MM-DD.json`.
/// Writes are throttled and also flushed on quit.
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

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.save()
        }
    }

    func addActiveAppTime(seconds: TimeInterval, bundleId: String, name: String) {
        rolloverIfNeeded()
        today.addApp(seconds: seconds, bundleId: bundleId, name: name)
        throttledSave()
    }

    func addActiveDomainTime(seconds: TimeInterval, domain: String) {
        rolloverIfNeeded()
        today.addDomain(seconds: seconds, domain: domain)
        throttledSave()
    }

    /// Combined app + website rows for today, sorted by time spent.
    func activitySummaries(using categories: CategoryStore) -> [ActivitySummary] {
        var rows: [ActivitySummary] = []
        for (bundleId, seconds) in today.secondsByApp {
            rows.append(ActivitySummary(
                kind: .app(bundleId),
                name: today.namesByApp[bundleId] ?? bundleId,
                seconds: seconds,
                category: categories.category(forApp: bundleId)
            ))
        }
        for (domain, seconds) in today.secondsByDomain {
            rows.append(ActivitySummary(
                kind: .website(domain),
                name: domain,
                seconds: seconds,
                category: categories.category(forDomain: domain)
            ))
        }
        return rows.sorted { $0.seconds > $1.seconds }
    }

    /// Total seconds today belonging to a given category (apps + websites).
    func seconds(for category: AppCategory, using categories: CategoryStore) -> TimeInterval {
        var total: TimeInterval = 0
        for (bundleId, seconds) in today.secondsByApp where categories.category(forApp: bundleId) == category {
            total += seconds
        }
        for (domain, seconds) in today.secondsByDomain where categories.category(forDomain: domain) == category {
            total += seconds
        }
        return total
    }

    func save() {
        lastSave = Date()
        let url = directory.appendingPathComponent("usage-\(today.dateKey).json")
        if let data = try? JSONEncoder().encode(today) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func throttledSave() {
        if Date().timeIntervalSince(lastSave) > 20 { save() }
    }

    private func rolloverIfNeeded() {
        let key = Self.dateKey(for: Date())
        guard key != currentDateKey else { return }
        save()
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
