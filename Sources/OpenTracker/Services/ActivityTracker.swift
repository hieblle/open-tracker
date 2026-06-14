import AppKit
import CoreGraphics
import Observation

/// Watches the frontmost application and accrues active time per app — and, for
/// supported browsers, per visited domain.
///
/// Tracking is tick based: every few seconds we look at the foreground app and,
/// as long as the user isn't idle, add the elapsed time. Browser domains are
/// fetched asynchronously (Apple Events can block) and cached.
@Observable
final class ActivityTracker {
    private(set) var currentAppName: String = "—"
    private(set) var currentBundleId: String?
    private(set) var currentActivity: String = "—" // app name, or domain while browsing
    private(set) var isIdle: Bool = false
    private(set) var isTracking: Bool = false

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let usage: UsageStore
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var workspaceObserver: NSObjectProtocol?
    @ObservationIgnored private var lastTick: Date?
    @ObservationIgnored private let scriptQueue = DispatchQueue(label: "at.neoclarity.OpenTracker.browser")
    @ObservationIgnored private var domainFetchInFlight = false
    @ObservationIgnored private var currentDomain: String?

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

        if BrowserScripting.isBrowser(currentBundleId) {
            refreshDomain()
        } else {
            currentDomain = nil
            currentActivity = currentAppName
        }
    }

    private func tick() {
        let now = Date()
        let delta = min(now.timeIntervalSince(lastTick ?? now), tickInterval * 3)
        lastTick = now

        if Self.systemIdleSeconds() >= TimeInterval(settings.idleThresholdSeconds) {
            isIdle = true
            if delta > 0 { usage.recordIdle(seconds: delta) }
            return
        }
        isIdle = false

        updateCurrentApp()
        guard delta > 0, let bundleId = currentBundleId else { return }

        if BrowserScripting.isBrowser(bundleId), let domain = currentDomain {
            usage.recordActive(kind: .website(domain: domain), seconds: delta)
            currentActivity = domain
        } else {
            usage.recordActive(kind: .app(bundleId: bundleId, name: currentAppName), seconds: delta)
            currentActivity = currentAppName
        }
    }

    /// Asynchronously refresh the active browser tab's domain into `currentDomain`.
    private func refreshDomain() {
        guard let bundleId = currentBundleId,
              BrowserScripting.isBrowser(bundleId),
              !domainFetchInFlight else { return }
        domainFetchInFlight = true
        scriptQueue.async { [weak self] in
            let domain = BrowserScripting.activeDomain(forBundleId: bundleId)
            DispatchQueue.main.async {
                guard let self else { return }
                self.currentDomain = domain
                if let domain { self.currentActivity = domain }
                self.domainFetchInFlight = false
            }
        }
    }

    /// Seconds since the most recent user input of any kind.
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
