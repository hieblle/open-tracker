import AppKit
import Observation

/// Owns "today's" usage aggregate (apps + website domains), persists it, and
/// loads historical days for the dashboard.
///
/// Data lives in `~/Library/Application Support/OpenTracker/usage-YYYY-MM-DD.json`.
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

    // MARK: Recording

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

    // MARK: Queries (day-scoped)

    /// Combined app + website rows for a day, sorted by time spent.
    func activitySummaries(in day: DayUsage, using categories: CategoryStore) -> [ActivitySummary] {
        var rows: [ActivitySummary] = []
        for (bundleId, seconds) in day.secondsByApp {
            rows.append(ActivitySummary(
                kind: .app(bundleId),
                name: day.namesByApp[bundleId] ?? bundleId,
                seconds: seconds,
                category: categories.category(forApp: bundleId)
            ))
        }
        for (domain, seconds) in day.secondsByDomain {
            rows.append(ActivitySummary(
                kind: .website(domain),
                name: domain,
                seconds: seconds,
                category: categories.category(forDomain: domain)
            ))
        }
        return rows.sorted { $0.seconds > $1.seconds }
    }

    /// Total seconds in a day belonging to a category (apps + websites).
    func seconds(for category: AppCategory, in day: DayUsage, using categories: CategoryStore) -> TimeInterval {
        var total: TimeInterval = 0
        for (bundleId, seconds) in day.secondsByApp where categories.category(forApp: bundleId) == category {
            total += seconds
        }
        for (domain, seconds) in day.secondsByDomain where categories.category(forDomain: domain) == category {
            total += seconds
        }
        return total
    }

    // Today-scoped conveniences (used by the menu bar panel).
    func activitySummaries(using categories: CategoryStore) -> [ActivitySummary] {
        activitySummaries(in: today, using: categories)
    }

    func seconds(for category: AppCategory, using categories: CategoryStore) -> TimeInterval {
        seconds(for: category, in: today, using: categories)
    }

    // MARK: History

    /// The aggregate for a given calendar day — live for today, from disk otherwise.
    func day(for date: Date) -> DayUsage {
        let key = Self.dateKey(for: date)
        if key == today.dateKey { return today }
        return Self.load(dateKey: key, in: directory) ?? DayUsage(dateKey: key)
    }

    /// The last `count` days, oldest first (today last).
    func recentDays(_ count: Int) -> [DayUsage] {
        let calendar = Calendar.current
        return (0..<count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map { day(for: $0) }
        }
    }

    /// Merge several days into one synthetic aggregate (for week/range totals).
    func merged(_ days: [DayUsage]) -> DayUsage {
        var out = DayUsage(dateKey: "range")
        for day in days {
            for (key, value) in day.secondsByApp { out.secondsByApp[key, default: 0] += value }
            for (key, value) in day.namesByApp where out.namesByApp[key] == nil { out.namesByApp[key] = value }
            for (key, value) in day.secondsByDomain { out.secondsByDomain[key, default: 0] += value }
        }
        return out
    }

    // MARK: Persistence

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
