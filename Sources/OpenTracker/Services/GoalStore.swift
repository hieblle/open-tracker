import Foundation
import Observation

/// User goals, persisted locally, plus progress evaluation against a day.
@Observable
final class GoalStore {
    private(set) var goals: [Goal]

    @ObservationIgnored private let key = "goals"

    init() {
        goals = UserDefaults.standard.data(forKey: "goals")
            .flatMap { try? JSONDecoder().decode([Goal].self, from: $0) } ?? []
    }

    func add(_ goal: Goal) {
        goals.append(goal)
        persist()
    }

    /// Add a template once — ignores duplicates of the same metric + direction.
    func addTemplate(_ template: GoalTemplate) {
        guard !hasGoal(metric: template.metric, direction: template.direction) else { return }
        add(Goal(
            id: UUID().uuidString,
            title: template.title,
            metric: template.metric,
            direction: template.direction,
            targetMinutes: template.defaultMinutes
        ))
    }

    func hasGoal(metric: GoalMetric, direction: GoalDirection) -> Bool {
        goals.contains { $0.metric == metric && $0.direction == direction }
    }

    /// Adjust a goal's daily target.
    func setTarget(_ minutes: Int, for id: String) {
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[index].targetMinutes = max(1, minutes)
        persist()
    }

    /// Flip between "at least" and "at most".
    func setDirection(_ direction: GoalDirection, for id: String) {
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[index].direction = direction
        persist()
    }

    func remove(id: String) {
        goals.removeAll { $0.id == id }
        persist()
    }

    /// Evaluate every goal against a day's data.
    func progress(day: DayUsage,
                  usage: UsageStore,
                  categories: CategoryStore,
                  projects: ProjectStore) -> [GoalProgress] {
        goals.map { goal in
            GoalProgress(
                goal: goal,
                currentSeconds: usage.seconds(for: goal.metric, in: day, using: categories, projects: projects)
            )
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static let templates: [GoalTemplate] = [
        GoalTemplate(id: "min-work", title: "Mindest-Arbeitszeit",
                     description: "Lege fest, wie viele Stunden du täglich mindestens arbeiten willst.",
                     metric: .workTime, direction: .atLeast, defaultMinutes: 480),
        GoalTemplate(id: "max-focus", title: "Mehr Fokuszeit",
                     description: "Steigere deine tägliche tiefe Fokuszeit für besseres, schnelleres Arbeiten.",
                     metric: .focusTime, direction: .atLeast, defaultMinutes: 240),
        GoalTemplate(id: "six-hour", title: "6-Stunden-Arbeitstag",
                     description: "Begrenze deine Arbeitszeit bewusst – mehr Output in weniger Zeit.",
                     metric: .workTime, direction: .atMost, defaultMinutes: 360),
        GoalTemplate(id: "limit-distract", title: "Weniger Ablenkung",
                     description: "Minimiere die Zeit mit ablenkenden Apps & Websites wie Social Media.",
                     metric: .distractingTime, direction: .atMost, defaultMinutes: 30),
        GoalTemplate(id: "more-breaks", title: "Mehr Pausen",
                     description: "Nimm dir bewusst mehr Pausenzeit und halte dich daran.",
                     metric: .breakTime, direction: .atLeast, defaultMinutes: 30),
    ]
}
