import Foundation

/// A single row in the "Apps" list: one app, its time today and its category.
struct AppUsageSummary: Identifiable {
    let bundleId: String
    let name: String
    let seconds: TimeInterval
    let category: AppCategory

    var id: String { bundleId }
}
