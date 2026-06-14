import SwiftUI

/// "Verwalten" tab: create projects, and set rating + project for every app and
/// website seen recently.
struct ManagementView: View {
    @Environment(UsageStore.self) private var usage
    @Environment(CategoryStore.self) private var categories
    @Environment(ProjectStore.self) private var projects

    @State private var newProjectName = ""

    var body: some View {
        let items = usage.knownActivities(daysBack: 14, using: categories)

        VStack(alignment: .leading, spacing: 22) {
            projectsSection
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("Apps & Websites").font(.headline)
                Text("Bewertung und Projekt pro App/Website festlegen (letzte 14 Tage).")
                    .font(.caption).foregroundStyle(.secondary)
                if items.isEmpty {
                    Text("Noch keine Daten – nutze den Mac etwas, dann erscheinen hier Apps & Websites.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        ManageRow(summary: item)
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Projekte").font(.headline)
            if projects.projects.isEmpty {
                Text("Noch keine Projekte. Lege eines an, um Apps & Websites zu bündeln.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(projects.projects) { project in
                    HStack(spacing: 8) {
                        Circle().fill(project.color).frame(width: 11, height: 11)
                        Text(project.name)
                        Spacer()
                        Button(role: .destructive) {
                            projects.deleteProject(id: project.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Projekt löschen")
                    }
                }
            }
            HStack {
                TextField("Neues Projekt…", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
                    .onSubmit(addProject)
                Button("Hinzufügen", action: addProject)
                    .disabled(newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        projects.addProject(name: name)
        newProjectName = ""
    }
}

/// One editable row: icon, name, rating picker, project menu.
struct ManageRow: View {
    let summary: ActivitySummary
    @Environment(CategoryStore.self) private var categories
    @Environment(ProjectStore.self) private var projects

    var body: some View {
        HStack(spacing: 12) {
            ActivityIcon(kind: summary.kind).frame(width: 18, height: 18)
            Text(summary.name)
                .frame(width: 190, alignment: .leading)
                .lineLimit(1)

            Picker("", selection: ratingBinding) {
                ForEach(AppCategory.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .fixedSize()

            Spacer(minLength: 8)

            projectMenu
        }
        .padding(.vertical, 3)
    }

    private var ratingBinding: Binding<AppCategory> {
        Binding(
            get: {
                switch summary.kind {
                case .app(let bundleId): return categories.category(forApp: bundleId)
                case .website(let domain): return categories.category(forDomain: domain)
                }
            },
            set: { categories.setCategory($0, for: summary) }
        )
    }

    private var currentProject: Project? {
        switch summary.kind {
        case .app(let bundleId): return projects.project(forApp: bundleId)
        case .website(let domain): return projects.project(forDomain: domain)
        }
    }

    private var projectMenu: some View {
        Menu {
            Button("Kein Projekt") { assign(nil) }
            if !projects.projects.isEmpty { Divider() }
            ForEach(projects.projects) { project in
                Button(project.name) { assign(project.id) }
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(currentProject?.color ?? Color.secondary.opacity(0.4))
                    .frame(width: 9, height: 9)
                Text(currentProject?.name ?? "Projekt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func assign(_ projectId: String?) {
        switch summary.kind {
        case .app(let bundleId): projects.assignApp(bundleId, to: projectId)
        case .website(let domain): projects.assignDomain(domain, to: projectId)
        }
    }
}
