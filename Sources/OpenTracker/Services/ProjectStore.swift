import Foundation
import Observation

/// User-created projects and the mapping of apps / websites to them.
///
/// Independent of the productive/neutral/distracting rating: a project is about
/// *what* you were working on, the rating is about *how* it counts.
@Observable
final class ProjectStore {
    private(set) var projects: [Project]
    private var appMap: [String: String]    // bundleId -> projectId
    private var domainMap: [String: String] // domain -> projectId

    @ObservationIgnored private let projectsKey = "projects"
    @ObservationIgnored private let appMapKey = "projectAppMap"
    @ObservationIgnored private let domainMapKey = "projectDomainMap"

    init() {
        let ud = UserDefaults.standard
        projects = ud.data(forKey: "projects")
            .flatMap { try? JSONDecoder().decode([Project].self, from: $0) } ?? []
        appMap = ud.data(forKey: "projectAppMap")
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        domainMap = ud.data(forKey: "projectDomainMap")
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
    }

    // MARK: Lookups

    func projectById(_ id: String) -> Project? {
        projects.first { $0.id == id }
    }

    func project(forApp bundleId: String) -> Project? {
        appMap[bundleId].flatMap(projectById)
    }

    func project(forDomain domain: String) -> Project? {
        domainMap[domain].flatMap(projectById)
    }

    // MARK: Project CRUD

    func addProject(name: String) {
        projects.append(Project(id: UUID().uuidString, name: name, colorIndex: projects.count))
        persistProjects()
    }

    func deleteProject(id: String) {
        projects.removeAll { $0.id == id }
        appMap = appMap.filter { $0.value != id }
        domainMap = domainMap.filter { $0.value != id }
        persistAll()
    }

    // MARK: Assignment

    func assignApp(_ bundleId: String, to projectId: String?) {
        appMap[bundleId] = projectId
        persistAppMap()
    }

    func assignDomain(_ domain: String, to projectId: String?) {
        domainMap[domain] = projectId
        persistDomainMap()
    }

    // MARK: Persistence

    private func persistProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
    }

    private func persistAppMap() {
        if let data = try? JSONEncoder().encode(appMap) {
            UserDefaults.standard.set(data, forKey: appMapKey)
        }
    }

    private func persistDomainMap() {
        if let data = try? JSONEncoder().encode(domainMap) {
            UserDefaults.standard.set(data, forKey: domainMapKey)
        }
    }

    private func persistAll() {
        persistProjects()
        persistAppMap()
        persistDomainMap()
    }
}
