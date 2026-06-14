import AppKit
import CoreGraphics
import Observation

/// Watches the frontmost application and accrues active time per app.
///
/// Tracking is **tick based**: every few seconds we look at the foreground app
/// and, as long as the user isn't idle, add the elapsed time to today's total.
/// This handles long uninterrupted sessions and idle gaps cleanly without
/// needing any special accessibility permissions — `NSWorkspace` exposes the
/// foreground app's bundle id directly.
@Observable
final class ActivityTracker {
    private(set) var currentAppName: String = "—"
    private(set) var currentBundleId: String?
    private(set) var isIdle: Bool = false
    private(set) var isTracking: Bool = false

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let usage: UsageStore
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var workspaceObserver: NSObjectProtocol?
    @ObservationIgnored private var lastTick: Date?

    /// How often we sample. Small enough to be accurate, large enough to be free.
    private let tickInterval: TimeInterval = 5

    init(settings: AppSettings, usage: UsageStore) {
        self.settings = settings
        self.usage = usage
    }

    func start() {
        guard !isTracking else { return }
        isTracking = true
        lastTick = Date()
        updateCurrentApp()

        // React instantly to app switches for a snappy "current app" readout.
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentApp()
        }

        let timer = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
            self.workspaceObserver = nil
        }
        isTracking = false
    }

    private func updateCurrentApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        currentBundleId = app.bundleIdentifier
        currentAppName = app.localizedName ?? app.bundleIdentifier ?? "Unbekannt"
    }

    private func tick() {
        let now = Date()
        // Real elapsed time, clamped so a wake-from-sleep can't dump a huge chunk.
        let delta = min(now.timeIntervalSince(lastTick ?? now), tickInterval * 3)
        lastTick = now

        if Self.systemIdleSeconds() >= TimeInterval(settings.idleThresholdSeconds) {
            isIdle = true
            return // user is away — don't accrue
        }
        isIdle = false

        updateCurrentApp()
        guard delta > 0, let bundleId = currentBundleId else { return }
        usage.addActiveTime(seconds: delta, bundleId: bundleId, name: currentAppName)
    }

    /// Seconds since the most recent user input of any kind.
    ///
    /// We take the minimum across a handful of event types rather than the
    /// `~0` "any event" sentinel, which isn't a valid `CGEventType` case in Swift.
    static func systemIdleSeconds() -> TimeInterval {
        let types: [CGEventType] = [
            .keyDown, .leftMouseDown, .rightMouseDown,
            .mouseMoved, .scrollWheel, .leftMouseDragged,
        ]
        let idles = types.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }
        return idles.min() ?? 0
    }
}
