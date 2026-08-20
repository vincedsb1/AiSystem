import Foundation

// MARK: - Overview Response (contract: project_skills.py `overview --json`)

/// Aggregated snapshot of every enabled project.
///
/// The backend is authoritative on `state`, per-project state, severity and
/// allowed actions. SwiftUI never recomputes any of these.
struct SystemOverviewResponse: Codable, Equatable, VersionedBackendPayload {
    let schemaVersion: Int
    let status: String
    let generatedAt: String
    let state: SystemState
    let summary: OverviewSummary
    let projects: [OverviewProject]
    let actions: [OverviewAction]
    let error: BackendError?

    var observedAt: Date? {
        ISO8601DateFormatter().date(from: generatedAt)
    }
}

struct OverviewSummary: Codable, Equatable {
    let projectsTotal: Int
    let projectsHealthy: Int
    let projectsAttention: Int
    let projectsError: Int
    let skillsTotal: Int
    let skillsManaged: Int
    let actionRequired: Int
    let expectedExceptions: Int
    let conflicts: Int
}

struct OverviewProject: Codable, Equatable, Identifiable {
    let name: String
    let root: String?
    let enabled: Bool
    let state: ProjectState
    let summary: SkillSummary
    let error: BackendError?

    var id: String { name }
}

struct OverviewAction: Codable, Equatable, Identifiable {
    let id: String
    let project: String
    let skill: String
    let canonicalId: String?
    let status: SkillStatus
    let severity: ActionSeverity
    let importable: Bool
    let allowedActions: [String]
}

// MARK: - Severity

enum ActionSeverity: String, Codable, Equatable {
    case attention
    case error

    var displayName: String {
        switch self {
        case .attention: return "Attention"
        case .error: return "Bloquant"
        }
    }

    var symbolName: String {
        switch self {
        case .attention: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

// MARK: - System State

enum SystemState: String, Codable, Equatable {
    /// No fresh observation available yet. Neutral, never rendered as an error.
    case unknown
    /// A check is running. UI-only: the backend never emits this value.
    case checking
    case healthy
    case attention
    case error

    var title: String {
        switch self {
        case .unknown: return "État du système inconnu"
        case .checking: return "Vérification en cours…"
        case .healthy: return "Tout est à jour"
        case .attention: return "Des éléments demandent votre attention"
        case .error: return "La vérification n'a pas pu être terminée"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .checking: return "arrow.triangle.2.circlepath"
        case .healthy: return "checkmark.circle.fill"
        case .attention: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Project State

enum ProjectState: String, Codable, Equatable {
    case unknown
    case healthy
    case attention
    case error
    case disabled

    var displayName: String {
        switch self {
        case .unknown: return "Non analysé"
        case .healthy: return "Sain"
        case .attention: return "Attention requise"
        case .error: return "Erreur"
        case .disabled: return "Désactivé"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .healthy: return "checkmark.circle.fill"
        case .attention: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .disabled: return "minus.circle"
        }
    }
}

// MARK: - Operation State

enum OperationStatus: String, Codable, CaseIterable {
    case queued
    case running
    case succeeded
    case partiallySucceeded
    case failed
    case cancelled

    var displayName: String {
        switch self {
        case .queued: return "En attente"
        case .running: return "En cours"
        case .succeeded: return "Réussi"
        case .partiallySucceeded: return "Réussi avec avertissements"
        case .failed: return "Échoué"
        case .cancelled: return "Annulé"
        }
    }

    var symbolName: String {
        switch self {
        case .queued: return "clock"
        case .running: return "arrow.triangle.2.circlepath"
        case .succeeded: return "checkmark.circle.fill"
        case .partiallySucceeded: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.octagon.fill"
        case .cancelled: return "minus.circle"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .queued, .running: return false
        default: return true
        }
    }
}

// MARK: - Write State

enum WriteState: String, Codable {
    case noChanges = "no_changes"
    case partialChanges = "partial_changes"
    case rolledBack = "rolled_back"
    case unknown
}
