import SwiftUI

/// "Ziele" tab: today's progress, an editable list of your goals (set the
/// target time, flip direction, delete), one-click templates, and a custom builder.
struct GoalsView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories
    @Environment(ProjectStore.self) private var projects
    @Environment(GoalStore.self) private var goals

    @State private var kind: GoalMetricKind = .focus
    @State private var direction: GoalDirection = .atLeast
    @State private var minutes: Int = 120
    @State private var projectId: String = ""

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 14)]

    var body: some View {
        let progress = goals.progress(day: usage.today, usage: usage, categories: categories, projects: projects)

        VStack(alignment: .leading, spacing: 22) {
            if progress.isEmpty {
                Text("Setze tägliche Ziele – etwa mindestens 4 h Fokus oder höchstens 30 min Ablenkung. Wähle eine Vorlage oder erstelle ein eigenes Ziel.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                GoalsCard(progress: progress)
            }

            if !goals.goals.isEmpty { myGoalsSection }

            templatesSection

            Divider()
            customBuilder
        }
    }

    // MARK: My goals (editable)

    private var myGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meine Ziele").font(.headline)
            Text("Zielzeit über die Pfeile anpassen, Richtung per Klick umschalten.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(goals.goals) { goal in
                HStack(spacing: 12) {
                    Image(systemName: "target").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(goal.title).font(.subheadline)
                        Text(metricLabel(goal.metric)).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)

                    Menu {
                        Button("Mindestens") { goals.setDirection(.atLeast, for: goal.id) }
                        Button("Höchstens") { goals.setDirection(.atMost, for: goal.id) }
                    } label: {
                        Text(goal.direction == .atLeast ? "mindestens" : "höchstens")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Stepper(value: Binding(
                        get: { goal.targetMinutes },
                        set: { goals.setTarget($0, for: goal.id) }
                    ), in: 15...1440, step: 15) {
                        Text(formatDuration(Double(goal.targetMinutes * 60)))
                            .monospacedDigit()
                            .frame(width: 86, alignment: .trailing)
                    }
                    .fixedSize()

                    Button(role: .destructive) {
                        goals.remove(id: goal.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Ziel löschen")
                }
                .padding(.vertical, 3)
                Divider().opacity(0.4)
            }
        }
    }

    // MARK: Templates

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vorlagen").font(.headline)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(GoalStore.templates) { template in
                    templateCard(template)
                }
            }
        }
    }

    private func templateCard(_ template: GoalTemplate) -> some View {
        let exists = goals.hasGoal(metric: template.metric, direction: template.direction)
        return VStack(alignment: .leading, spacing: 8) {
            Text(template.title).font(.subheadline.bold())
            Text(template.description)
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                goals.addTemplate(template)
            } label: {
                Label(exists ? "Hinzugefügt" : "Hinzufügen",
                      systemImage: exists ? "checkmark" : "plus").font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(exists)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }

    // MARK: Custom builder

    private var customBuilder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Eigenes Ziel").font(.headline)
            HStack(spacing: 10) {
                Picker("", selection: $direction) {
                    Text("Mindestens").tag(GoalDirection.atLeast)
                    Text("Höchstens").tag(GoalDirection.atMost)
                }
                .fixedSize()

                Picker("", selection: $kind) {
                    ForEach(GoalMetricKind.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()

                if kind == .project {
                    Picker("", selection: $projectId) {
                        Text("Projekt wählen…").tag("")
                        ForEach(projects.projects) { Text($0.name).tag($0.id) }
                    }
                    .fixedSize()
                }

                Stepper(value: $minutes, in: 15...1440, step: 15) {
                    Text(formatDuration(Double(minutes * 60))).monospacedDigit().frame(width: 86, alignment: .trailing)
                }
                .fixedSize()

                Button("Hinzufügen", action: addCustom)
                    .disabled(kind == .project && projectId.isEmpty)
            }
        }
    }

    // MARK: Helpers

    private func metricLabel(_ metric: GoalMetric) -> String {
        switch metric {
        case .workTime: return "Arbeitszeit"
        case .focusTime: return "Fokuszeit"
        case .neutralTime: return "Neutrale Zeit"
        case .distractingTime: return "Ablenkung"
        case .breakTime: return "Pausen"
        case .project(let id): return "Projekt: \(projects.projectById(id)?.name ?? "—")"
        }
    }

    private func addCustom() {
        let metric = kind.metric(projectId: projectId)
        let baseName: String
        if case .project = metric, let project = projects.projectById(projectId) {
            baseName = "Projekt: \(project.name)"
        } else {
            baseName = kind.title
        }
        let prefix = direction == .atLeast ? "Min." : "Max."
        goals.add(Goal(
            id: UUID().uuidString,
            title: "\(prefix) \(baseName)",
            metric: metric,
            direction: direction,
            targetMinutes: minutes
        ))
    }
}
