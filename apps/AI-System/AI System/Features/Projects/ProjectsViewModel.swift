import Foundation
import Observation

// MARK: - Skill filter

enum SkillFilter: String, CaseIterable, Identifiable {
    case all
    case toReview
    case synced
    case exceptions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "Tous"
        case .toReview: return "À examiner"
        case .synced: return "Synchronisés"
        case .exceptions: return "Exceptions"
        }
    }

    /// Backend severity is authoritative; the filter only selects rows.
    func matches(_ skill: SkillRow) -> Bool {
        switch self {
        case .all:
            return true
        case .toReview:
            return skill.requiresAction
        case .synced:
            return skill.status == .managedSynced
        case .exceptions:
            return skill.status == .expectedClaudeOnly || skill.status == .expectedCodexOnly
        }
    }
}

// MARK: - View model

/// Drives the Projects destination in read-only mode.
///
/// The project list and every skill status come from the backend. This model
/// only sorts, filters and selects (spec 20.6).
@MainActor
@Observable
final class ProjectsViewModel {
    private let service: ProjectSkillsService

    // Project list
    private(set) var projects: [OverviewProject] = []
    private(set) var isLoadingProjects = false
    private(set) var projectsError: String?
    private(set) var hasAttemptedLoad = false

    // Selected project detail
    private(set) var scan: ScanProjectResponse?
    private(set) var isScanning = false
    private(set) var scanError: String?
    private(set) var scannedProjectName: String?

    // Purely presentational state
    var selectedProjectName: String? {
        didSet {
            guard selectedProjectName != oldValue else { return }
            searchText = ""
            filter = .all
            scan = nil
            scanError = nil
            scannedProjectName = nil
        }
    }
    var searchText = ""
    var filter: SkillFilter = .all

    init(service: ProjectSkillsService = ProjectSkillsService()) {
        self.service = service
    }

    // MARK: - Derived list

    /// Errors first, then attention, then the rest; alphabetical inside each
    /// group (spec 10.2).
    var sortedProjects: [OverviewProject] {
        projects.sorted { lhs, rhs in
            let lhsRank = Self.rank(lhs.state)
            let rhsRank = Self.rank(rhs.state)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func rank(_ state: ProjectState) -> Int {
        switch state {
        case .error: return 0
        case .attention: return 1
        case .healthy: return 2
        case .unknown: return 3
        case .disabled: return 4
        }
    }

    var selectedProject: OverviewProject? {
        guard let selectedProjectName else { return nil }
        return projects.first { $0.name == selectedProjectName }
    }

    var isEmpty: Bool { hasAttemptedLoad && projects.isEmpty && projectsError == nil }

    // MARK: - Derived detail

    var summary: SkillSummary? { scan?.summary }

    /// Targets the project actually installs shared skills on. Used so a
    /// platform the project does not target reads as "non concerné" rather
    /// than "absent".
    var sharedTargets: [String] { scan?.project?.effectiveSharedTargets ?? ["codex"] }

    var allSkills: [SkillRow] { scan?.skills ?? [] }

    /// Rows after search and filter, keeping the backend ordering.
    var visibleSkills: [SkillRow] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return allSkills.filter { skill in
            guard filter.matches(skill) else { return false }
            guard !query.isEmpty else { return true }
            if skill.name.localizedCaseInsensitiveContains(query) { return true }
            if let canonical = skill.canonicalId,
               canonical.localizedCaseInsensitiveContains(query) { return true }
            return false
        }
    }

    var hasActiveFilter: Bool {
        filter != .all || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func count(for filter: SkillFilter) -> Int {
        allSkills.filter(filter.matches).count
    }

    /// Detail state of the selected project, distinct from the list entry so a
    /// failed scan does not rewrite the project's known state.
    var detailState: ProjectState {
        if isScanning { return selectedProject?.state ?? .unknown }
        if scan != nil { return selectedProject?.state ?? .unknown }
        if scanError != nil { return .error }
        return selectedProject?.state ?? .unknown
    }

    /// Primary action label follows spec 10.4.
    var primaryActionTitle: String {
        guard let project = selectedProject else { return "Analyser" }
        if scan == nil { return "Analyser" }
        switch project.state {
        case .error: return "Examiner le conflit"
        case .attention: return "Vérifier"
        case .healthy: return "Vérifier"
        case .unknown, .disabled: return "Analyser"
        }
    }

    var lastScanText: String? {
        guard let generatedAt = scan?.generatedAt,
              let date = ISO8601DateFormatter().date(from: generatedAt)
        else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var isBusy: Bool { isLoadingProjects || isScanning }

    // MARK: - Loading

    /// Loads the project list. The selection is preserved when the project
    /// still exists (FR-PROJ-01).
    func loadProjects() async {
        guard !isLoadingProjects else { return }
        isLoadingProjects = true
        hasAttemptedLoad = true
        defer { isLoadingProjects = false }

        switch await service.overview() {
        case .success(let payload):
            projects = payload.projects
            projectsError = nil

            if let selected = selectedProjectName,
               !payload.projects.contains(where: { $0.name == selected }) {
                // The project disappeared between two loads.
                selectedProjectName = nil
            }
        case .failure(let error):
            // Stale list is intentionally preserved (spec 22.4).
            projectsError = error.errorDescription
        }
    }

    /// Scans the selected project. Read-only.
    func scanSelectedProject() async {
        guard let name = selectedProjectName, !isScanning else { return }
        isScanning = true
        defer { isScanning = false }

        switch await service.scan(project: name) {
        case .success(let payload):
            // Guard against a selection change while the scan was in flight.
            guard selectedProjectName == name else { return }
            scan = payload
            scannedProjectName = name
            scanError = nil
        case .failure(let error):
            guard selectedProjectName == name else { return }
            scanError = error.errorDescription
        }
    }

    /// Re-runs the list and the current detail together.
    func refreshAll() async {
        await loadProjects()
        await scanSelectedProject()
    }

    /// Selects a project handed over by another destination and preselects the
    /// review filter when it has pending actions (spec 10.8).
    func select(projectNamed name: String, focusActions: Bool) {
        selectedProjectName = name
        if focusActions {
            filter = .toReview
        }
    }

    func clearFilters() {
        searchText = ""
        filter = .all
    }

    func dismissScanError() {
        scanError = nil
    }
}
