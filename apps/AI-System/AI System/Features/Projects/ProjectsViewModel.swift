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
    private let commandCenter: CommandCenter?

    // Project list
    private(set) var projects: [OverviewProject] = []
    /// The same structured overview used to populate the project list. This
    /// lets Quick Command stay useful even when Projects is the first screen
    /// opened in a restored session.
    private(set) var overviewSnapshot: SystemOverviewResponse?
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

    // MARK: Mutating operations

    /// Operation state per skill, so only the affected row shows progress and
    /// a second submission is impossible (spec 11.4 / 22.3).
    private(set) var skillOperations: [String: SkillOperationState] = [:]

    /// Skill the import sheet is confirming, if any.
    var importCandidate: SkillRow?

    private(set) var isSyncing = false
    private(set) var lastActionSummary: String?
    private(set) var lastActionSucceeded = true

    init(
        service: ProjectSkillsService = ProjectSkillsService(),
        commandCenter: CommandCenter? = nil
    ) {
        self.service = service
        self.commandCenter = commandCenter
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

    var emptyStateTitle: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            return "Aucun skill ne correspond à “" + query + "”"
        }

        switch filter {
        case .all:
            return "Aucun skill dans ce projet"
        case .toReview:
            return "Aucun skill à examiner"
        case .synced:
            return "Aucun skill synchronisé"
        case .exceptions:
            return "Aucune exception attendue"
        }
    }

    var emptyStateDescription: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            return "Modifiez votre recherche ou effacez-la."
        }

        switch filter {
        case .all:
            return "Ce projet ne déclare aucun skill."
        case .toReview:
            return "Ce projet ne demande aucune action."
        case .synced:
            return "Aucun skill n’est actuellement synchronisé."
        case .exceptions:
            return "Ce projet ne déclare aucune exception attendue."
        }
    }

    var emptyStateActionTitle: String? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty || filter == .toReview {
            return filter == .toReview && query.isEmpty
                ? "Afficher tous les skills"
                : "Effacer la recherche"
        }
        return nil
    }

    var headerSummaryText: String {
        guard let summary else { return "Skills non vérifiés" }
        let skills = "\(summary.managed) "
            + (summary.managed == 1 ? "skill synchronisé" : "skills synchronisés")
        let exceptions = "\(summary.expectedExceptions) "
            + (summary.expectedExceptions == 1 ? "exception attendue" : "exceptions attendues")
        return skills + " · " + exceptions
    }

    var compositionText: String? {
        guard let summary else { return nil }
        return "Composition : \(summary.shared) partagés · \(summary.projectSpecific) spécifiques"
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
        return AppFormatters.observationDate(date)
    }

    var isBusy: Bool { isLoadingProjects || isScanning }

    /// True while any mutating operation runs. Navigation and reading stay
    /// available; only incompatible operations are blocked (spec 22.3).
    var isMutating: Bool {
        isSyncing
            || skillOperations.values.contains { $0.isRunning }
            || commandCenter?.isRunning == true
    }

    func operationState(for skill: SkillRow) -> SkillOperationState {
        skillOperations[skill.name] ?? .idle
    }

    /// The interface only offers what the backend declared allowed.
    func canImport(_ skill: SkillRow) -> Bool {
        skill.importable
            && skill.allowedActions.contains("import")
            && !isMutating
    }

    func canSyncProject() -> Bool {
        guard let summary else { return false }
        let repairable = allSkills.contains { skill in
            skill.allowedActions.contains("sync")
        }
        return repairable && summary.conflicts == 0 && !isMutating
    }

    /// Source the backend detected for an importable skill.
    func importSource(for skill: SkillRow) -> ImportSource? {
        if skill.presence.codex && !skill.presence.claude { return .codex }
        if skill.presence.claude && !skill.presence.codex { return .claude }
        return nil
    }

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
            overviewSnapshot = payload
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

    func clearEmptyState() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            searchText = ""
        } else {
            filter = .all
        }
    }

    func dismissScanError() {
        scanError = nil
    }

    func dismissActionSummary() {
        lastActionSummary = nil
    }

    // MARK: - Import

    /// Imports a skill, then rescans so the row reflects its final state
    /// (spec 11.5). A double submission is refused up front.
    func importSkill(
        _ skill: SkillRow,
        source: ImportSource,
        recordingIn store: ActivityStore? = nil,
        commandCenter externalCommandCenter: CommandCenter? = nil
    ) async {
        guard let project = selectedProjectName else { return }
        guard operationState(for: skill) != .running, !isMutating else { return }
        let activeCommandCenter = externalCommandCenter ?? commandCenter
        guard activeCommandCenter?.canStart != false else { return }

        skillOperations[skill.name] = .running
        importCandidate = nil

        let activityId = store?.begin(
            kind: .importSkill,
            displayName: "Import de \(skill.name)",
            scope: .skill(project, skill.name)
        )
        let operationID = activeCommandCenter?.begin(
            kind: .importSkill,
            displayName: "Import de \(skill.name)",
            target: "\(project) · \(skill.name)",
            activityID: activityId
        )

        let result = await service.importSkill(
            project: project,
            skill: skill.name,
            source: source
        )

        switch result {
        case .success(let response):
            skillOperations[skill.name] = .succeeded(response.summary)
            lastActionSummary = response.summary
            lastActionSucceeded = true
            store?.finish(
                activityId ?? UUID(),
                status: response.outcome.isSuccess ? .succeeded : .failed,
                summary: response.summary,
                changes: response.changes
            )
            if let operationID {
                activeCommandCenter?.finish(
                    operationID: operationID,
                    status: response.outcome.isSuccess ? .succeeded : .failed,
                    headline: store?.activity(activityId ?? UUID())?.receipt?.headline
                        ?? (response.outcome.isSuccess
                            ? "\(skill.name) est maintenant géré"
                            : "L’import de \(skill.name) a échoué"),
                    statusMessage: response.summary
                )
            }
            await scanSelectedProject()
        case .failure(let error):
            let message = failureMessage(for: error)
            skillOperations[skill.name] = .failed(message)
            lastActionSummary = message
            lastActionSucceeded = false
            store?.finish(
                activityId ?? UUID(),
                status: .failed,
                summary: message,
                error: activityError(for: error)
            )
            if let operationID {
                activeCommandCenter?.finish(
                    operationID: operationID,
                    status: .failed,
                    headline: "L’import de \(skill.name) a échoué",
                    statusMessage: message
                )
            }
        }
    }

    // MARK: - Sync

    /// Synchronises the selected project, then rescans.
    func syncSelectedProject(
        recordingIn store: ActivityStore? = nil,
        commandCenter externalCommandCenter: CommandCenter? = nil
    ) async {
        guard let project = selectedProjectName, !isMutating else { return }
        let activeCommandCenter = externalCommandCenter ?? commandCenter
        guard activeCommandCenter?.canStart != false else { return }
        isSyncing = true

        let activityId = store?.begin(
            kind: .sync,
            displayName: "Synchronisation de \(project)",
            scope: .project(project)
        )
        let operationID = activeCommandCenter?.begin(
            kind: .sync,
            displayName: "Synchronisation de \(project)",
            target: project,
            activityID: activityId
        )

        let result = await service.syncProject(project: project)
        isSyncing = false

        switch result {
        case .success(let response):
            lastActionSummary = response.summary
            lastActionSucceeded = response.outcome.isSuccess
            store?.finish(
                activityId ?? UUID(),
                status: response.outcome.isSuccess ? .succeeded : .partiallySucceeded,
                summary: response.summary,
                changes: response.changes,
                warningCount: response.changes?.conflicts ?? 0
            )
            if let operationID {
                activeCommandCenter?.finish(
                    operationID: operationID,
                    status: response.outcome.isSuccess ? .succeeded : .partiallySucceeded,
                    headline: store?.activity(activityId ?? UUID())?.receipt?.headline
                        ?? "\(project) synchronisé",
                    statusMessage: response.summary
                )
            }
            await scanSelectedProject()
            await loadProjects()
        case .failure(let error):
            let message = failureMessage(for: error)
            lastActionSummary = message
            lastActionSucceeded = false
            store?.finish(
                activityId ?? UUID(),
                status: .failed,
                summary: message,
                error: activityError(for: error)
            )
            if let operationID {
                activeCommandCenter?.finish(
                    operationID: operationID,
                    status: .failed,
                    headline: "La synchronisation de \(project) a échoué",
                    statusMessage: message
                )
            }
        }
    }

    /// Structured error carried into the activity record.
    private func activityError(for error: ProjectSkillsServiceError) -> ActivityError {
        var writeState: ActionWriteState?
        if case .backend(let backendError) = error, let raw = backendError.writeState {
            writeState = ActionWriteState(rawValue: raw)
        }
        return ActivityError(
            code: error.code,
            message: error.errorDescription ?? "Erreur inconnue.",
            writeState: writeState,
            retryable: error.isRetryable
        )
    }

    /// Failure copy always states whether files were modified (spec 17.3).
    private func failureMessage(for error: ProjectSkillsServiceError) -> String {
        let reason = error.errorDescription ?? "Erreur inconnue."
        guard case .backend(let backendError) = error,
              let raw = backendError.writeState,
              let state = ActionWriteState(rawValue: raw)
        else { return reason }
        return "\(reason) \(state.description)"
    }
}
