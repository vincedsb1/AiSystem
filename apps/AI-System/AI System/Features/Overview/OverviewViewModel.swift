import Foundation
import Observation

/// Drives the Overview destination.
///
/// Loading rules (spec 22.4): an in-flight refresh keeps the previous content
/// visible, a successful decode replaces it atomically, and a failed refresh
/// keeps the stale content alongside an inline error.
@MainActor
@Observable
final class OverviewViewModel {
    private let service: ProjectSkillsService

    /// Last successfully decoded snapshot. Never cleared by a failed refresh.
    private(set) var overview: SystemOverviewResponse?
    private(set) var isLoading = false
    private(set) var isRunningCheck = false
    private(set) var errorMessage: String?
    private(set) var errorIsRetryable = true
    private(set) var lastCheckSucceeded: Bool?

    /// Set to true once a load has been attempted, so the initial neutral
    /// `unknown` state is not confused with a completed empty observation.
    private(set) var hasAttemptedLoad = false

    init(service: ProjectSkillsService = ProjectSkillsService()) {
        self.service = service
    }

    // MARK: - Derived presentation state

    /// Global state shown by the header. `unknown` stays neutral (FR-STATE-04)
    /// and a healthy state is only claimed after a valid dated observation
    /// (FR-STATE-06).
    var displayState: SystemState {
        if isLoading || isRunningCheck {
            return .checking
        }
        if let overview {
            return overview.state
        }
        if errorMessage != nil {
            return .error
        }
        return .unknown
    }

    var summary: OverviewSummary? { overview?.summary }

    /// Actions ranked by the backend; blocking ones first.
    var actions: [OverviewAction] { overview?.actions ?? [] }

    /// The Overview never lists more than a handful of actions (spec 9.3).
    var topActions: [OverviewAction] { Array(actions.prefix(5)) }

    var remainingActionCount: Int { max(0, actions.count - topActions.count) }

    var projects: [OverviewProject] { overview?.projects ?? [] }

    /// Projects needing attention, most severe first, for quick navigation.
    var projectsNeedingAttention: [OverviewProject] {
        projects
            .filter { $0.state == .error || $0.state == .attention }
            .sorted { lhs, rhs in
                if lhs.state != rhs.state {
                    return lhs.state == .error
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    var lastObservationText: String? {
        guard let date = overview?.observedAt else { return nil }
        return AppFormatters.observationDate(date)
    }

    /// Header description, expressed in business terms rather than mechanics.
    var stateDescription: String {
        switch displayState {
        case .unknown:
            return "Analysez les projets et leurs skills pour connaître leur état."
        case .checking:
            return overview == nil
                ? "Analyse des projets et des skills en cours…"
                : "Actualisation de l’état du système…"
        case .healthy:
            guard let summary else { return "Aucune action requise." }
            return "\(summary.projectsTotal) \(pluralize(summary.projectsTotal, "projet", "projets")) vérifiés et "
                + "\(summary.skillsManaged) skills gérés. Aucune action n’est requise."
        case .attention:
            guard let summary else { return "Des éléments demandent votre attention." }
            var parts: [String] = []
            if summary.projectsAttention > 0 {
                parts.append("\(summary.projectsAttention) \(pluralize(summary.projectsAttention, "projet", "projets")) concernés")
            }
            if summary.conflicts > 0 {
                parts.append("\(summary.conflicts) \(pluralize(summary.conflicts, "conflit", "conflits"))")
            }
            let detail = parts.isEmpty ? "" : " : " + parts.joined(separator: ", ")
            return "\(summary.actionRequired) \(pluralize(summary.actionRequired, "élément", "éléments")) à examiner\(detail)."
        case .error:
            return errorMessage ?? "Le backend n'a pas pu produire un état exploitable."
        }
    }

    /// Attention title carries the count, per spec 9.2.
    var stateTitle: String {
        if displayState == .attention, let summary {
            return "\(summary.actionRequired) \(pluralize(summary.actionRequired, "élément demande", "éléments demandent")) votre attention"
        }
        return displayState.title
    }

    var isBusy: Bool { isLoading || isRunningCheck }

    // MARK: - Actions

    /// Read-only refresh. Safe to call on appear.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        hasAttemptedLoad = true
        defer { isLoading = false }

        switch await service.overview() {
        case .success(let payload):
            overview = payload
            errorMessage = nil
            errorIsRetryable = true
        case .failure(let error):
            // Stale content is intentionally preserved (spec 22.4).
            errorMessage = error.errorDescription
            errorIsRetryable = error.isRetryable
        }
    }

    /// Primary action: runs the official global check (FR-OV-01), then reloads
    /// the snapshot so the header reflects the fresh observation.
    ///
    /// The operation is recorded as an activity so its result has a context
    /// instead of living in a global `lastResult` (spec 20.5).
    func runCheckThenRefresh(recordingIn store: ActivityStore? = nil) async {
        guard !isBusy else { return }
        isRunningCheck = true
        lastCheckSucceeded = nil

        let activityId = store?.begin(
            kind: .check,
            displayName: "Vérification du système",
            scope: .global
        )

        let result = await service.runFullCheck()
        lastCheckSucceeded = result.succeeded
        isRunningCheck = false

        await load()

        if !result.succeeded && errorMessage == nil {
            errorMessage = "La vérification globale s'est terminée en erreur."
            errorIsRetryable = true
        }

        if let store, let activityId {
            let succeeded = result.succeeded
            store.finish(
                activityId,
                status: succeeded ? .succeeded : .failed,
                summary: succeeded
                    ? checkSummary()
                    : "La vérification globale s'est terminée en erreur.",
                error: succeeded ? nil : ActivityError(
                    code: nil,
                    message: "La vérification globale s'est terminée en erreur.",
                    writeState: .noChanges,
                    retryable: true
                ),
                technical: TechnicalDetails(
                    action: "check",
                    arguments: [],
                    exitCode: result.exitCode,
                    duration: result.duration,
                    stdout: result.stdout,
                    stderr: result.stderr,
                    logPath: AISystemPaths.lastLog
                )
            )
        }
    }

    /// Business conclusion of a check, never derived from stdout (spec 21.8).
    private func checkSummary() -> String {
        guard let summary else { return "Vérification terminée." }
        if summary.actionRequired == 0 {
            return "\(summary.projectsTotal) projets vérifiés, aucune action requise."
        }
        return "\(summary.actionRequired) élément(s) à traiter sur "
            + "\(summary.projectsTotal) projets."
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Helpers

    private func pluralize(_ count: Int, _ singular: String, _ plural: String) -> String {
        count <= 1 ? singular : plural
    }
}
