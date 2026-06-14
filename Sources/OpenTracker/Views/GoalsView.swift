import SwiftUI

/// "Ziele" tab: today's goal progress, one-click templates, a custom builder,
/// and management of existing goals.
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
                Text("Noch keine Ziele. Wähle unten eine Vorlage oder erstelle ein eigenes Ziel.")
                    .foregroundStyle(.secondary)
            } else {
                GoalsCard(progress: progress)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Vorlagen").font(.headline)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                    ForEach(GoalStore.templates) { template in
                        templateCard(template)
                    }
                }
            }

            Divider()
            customBuilder

            if !goals.goals.isEmpty {
                Divider()
                manageSection
            }
        }
    }

    private func templateCard(_ template: GoalTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.title).font(.subheadline.bold())
            Text(template.description)
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                goals.addTemplate(template)
            } label: {
                Label("Hinzufügen", systemImage: "plus").font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }

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

                Stepper("\(minutes) min", value: $minutes, in: 15...720, step: 15)
                    .fixedSize()

                Button("Ziel hinzufügen", action: addCustom)
                    .disabled(kind == .project && projectId.isEmpty)
            }
        }
    }

    private var manageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meine Ziele").font(.headline)
            ForEach(goals.goals) { goal in
                HStack {
                    Text(goal.direction == .atLeast ? "≥" : "≤").foregroundStyle(.secondary)
                    Text(goal.title)
                    Spacer()
                    Text("\(goal.targetMinutes) min").font(.caption).foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        goals.remove(id: goal.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
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
