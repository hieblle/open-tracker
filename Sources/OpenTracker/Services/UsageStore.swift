import AppKit
import Observation

/// Owns "today's" usage (totals + timeline), persists it, and answers both
/// simple totals and derived metrics for the dashboard.
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

    /// Record active foreground time: updates totals and extends the timeline.
    func recordActive(kind: ActivitySegment.Kind, seconds: TimeInterval) {
        rolloverIfNeeded()
        switch kind {
        case .app(let bundleId, let name): today.addApp(seconds: seconds, bundleId: bundleId, name: name)
        case .website(let domain): today.addDomain(seconds: seconds, domain: domain)
        case .idle: break
        }
        appendSegment(kind: kind, seconds: seconds)
        throttledSave()
    }

    /// Record an idle (break) tick: timeline only, never counted as active.
    func recordIdle(seconds: TimeInterval) {
        rolloverIfNeeded()
        appendSegment(kind: .idle, seconds: seconds)
        throttledSave()
    }

    private func appendSegment(kind: ActivitySegment.Kind, seconds: TimeInterval) {
        let now = Date()
        if var last = today.segments.last, last.kind == kind {
            last.end = now
            today.segments[today.segments.count - 1] = last
        } else {
            today.segments.append(ActivitySegment(start: now.addingTimeInterval(-seconds), end: now, kind: kind))
        }
    }

    // MARK: Totals (day-scoped)

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

    // MARK: Derived metrics

    /// Focus time, breaks, context switches and focus sessions for a day.
    func metrics(in day: DayUsage, using categories: CategoryStore) -> DayMetrics {
        var m = DayMetrics.zero
        m.focusSeconds = seconds(for: .productive, in: day, using: categories)
        m.neutralSeconds = seconds(for: .neutral, in: day, using: categories)
        m.distractingSeconds = seconds(for: .distracting, in: day, using: categories)

        var currentFocusRun: Double = 0
        var lastActiveIdentity: String?

        func closeFocusRun() {
            m.longestFocusSeconds = max(m.longestFocusSeconds, currentFocusRun)
            if currentFocusRun >= DayMetrics.focusSessionMinimum { m.focusSessionCount += 1 }
            currentFocusRun = 0
        }

        for segment in day.segments {
            switch segment.kind {
            case .idle:
                if segment.seconds >= DayMetrics.breakMinimum {
                    m.breakCount += 1
                    m.breakSeconds += segment.seconds
                }
                closeFocusRun()
            case .app(let bundleId, _):
                if let last = lastActiveIdentity, last != bundleId { m.contextSwitches += 1 }
                lastActiveIdentity = bundleId
                if categories.category(forApp: bundleId) == .productive {
                    currentFocusRun += segment.seconds
                } else {
                    closeFocusRun()
                }
            case .website(let domain):
                if let last = lastActiveIdentity, last != domain { m.contextSwitches += 1 }
                lastActiveIdentity = domain
                if categories.category(forDomain: domain) == .productive {
                    currentFocusRun += segment.seconds
                } else {
                    closeFocusRun()
                }
            }
        }
        closeFocusRun()
        return m
    }

    /// Meta-analysis: focus fragmentation, app/tab switches, and the activities
    /// that most often interrupt flow.
    func focusAnalysis(in day: DayUsage, using categories: CategoryStore) -> FocusAnalysis {
        func rating(of kind: ActivitySegment.Kind) -> AppCategory {
            switch kind {
            case .app(let bundleId, _): return categories.category(forApp: bundleId)
            case .website(let domain): return categories.category(forDomain: domain)
            case .idle: return .neutral
            }
        }
        func label(of segment: ActivitySegment) -> String {
            switch segment.kind {
            case .app(_, let name): return name
            case .website(let domain): return domain
            case .idle: return "Pause"
            }
        }

        var blockDurations: [Double] = []
        var deep = 0.0
        var scattered = 0.0
        var interrupterCounts: [String: Int] = [:]
        var appSwitches = 0
        var tabSwitches = 0

        var currentRun = 0.0
        var previousActive: ActivitySegment.Kind?

        func closeRun(interruptedBy interrupter: ActivitySegment?) {
            guard currentRun > 0 else { return }
            blockDurations.append(currentRun)
            if currentRun >= DayMetrics.focusSessionMinimum { deep += currentRun } else { scattered += currentRun }
            if currentRun >= FocusAnalysis.interruptionFocusMinimum, let interrupter {
                interrupterCounts[label(of: interrupter), default: 0] += 1
            }
            currentRun = 0
        }

        for segment in day.segments {
            if segment.isIdle {
                closeRun(interruptedBy: segment)
                continue
            }
            if let previous = previousActive {
                switch (previous, segment.kind) {
                case (.app(let a, _), .app(let b, _)): if a != b { appSwitches += 1 }
                case (.website(let a), .website(let b)): if a != b { tabSwitches += 1 }
                case (.app, .website), (.website, .app): appSwitches += 1
                default: break
                }
            }
            previousActive = segment.kind

            if rating(of: segment.kind) == .productive {
                currentRun += segment.seconds
            } else {
                closeRun(interruptedBy: segment)
            }
        }
        closeRun(interruptedBy: nil)

        let totalFocus = deep + scattered
        return FocusAnalysis(
            focusBlockCount: blockDurations.count,
            averageFocusBlockSeconds: blockDurations.isEmpty ? 0 : totalFocus / Double(blockDurations.count),
            deepFocusSeconds: deep,
            scatteredFocusSeconds: scattered,
            appSwitches: appSwitches,
            tabSwitches: tabSwitches,
            interrupters: interrupterCounts
                .map { FocusInterrupter(label: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
        )
    }

    // MARK: History

    func day(for date: Date) -> DayUsage {
        let key = Self.dateKey(for: date)
        if key == today.dateKey { return today }
        return Self.load(dateKey: key, in: directory) ?? DayUsage(dateKey: key)
    }

    func recentDays(_ count: Int) -> [DayUsage] {
        let calendar = Calendar.current
        return (0..<count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map { day(for: $0) }
        }
    }

    func merged(_ days: [DayUsage]) -> DayUsage {
        var out = DayUsage(dateKey: "range")
        for day in days {
            for (key, value) in day.secondsByApp { out.secondsByApp[key, default: 0] += value }
            for (key, value) in day.namesByApp where out.namesByApp[key] == nil { out.namesByApp[key] = value }
            for (key, value) in day.secondsByDomain { out.secondsByDomain[key, default: 0] += value }
            out.segments.append(contentsOf: day.segments)
        }
        return out
    }

    // MARK: Projects

    /// Time per project for a day (only assigned apps/websites).
    func projectTotals(in day: DayUsage, using projects: ProjectStore) -> [ProjectTotal] {
        var totals: [String: Double] = [:]
        for (bundleId, seconds) in day.secondsByApp {
            if let project = projects.project(forApp: bundleId) { totals[project.id, default: 0] += seconds }
        }
        for (domain, seconds) in day.secondsByDomain {
            if let project = projects.project(forDomain: domain) { totals[project.id, default: 0] += seconds }
        }
        return totals.compactMap { id, seconds in
            projects.projectById(id).map { ProjectTotal(project: $0, seconds: seconds) }
        }
        .sorted { $0.seconds > $1.seconds }
    }

    /// Unique apps & websites seen over the last `daysBack` days — for the
    /// "Verwalten" view, so the user can categorize/assign even past items.
    func knownActivities(daysBack: Int, using categories: CategoryStore) -> [ActivitySummary] {
        activitySummaries(in: merged(recentDays(daysBack)), using: categories)
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
