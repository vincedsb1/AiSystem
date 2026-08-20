import Foundation

// MARK: - System Overview (Composed from Projects and Summary)

/// Overview of the entire AI System health state.
/// Composed from list-projects and individual scan results.
struct SystemOverview: Codable {
    let generatedAt: String
    let globalState: SystemState
    let projectsTotal: Int
    let projectsHealthy: Int
    let projectsAttention: Int
    let projectsError: Int
    let actionRequired: Int
    let expectedExceptions: Int
    let lastCheckedAt: String?

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case globalState
        case projectsTotal
        case projectsHealthy
        case projectsAttention
        case projectsError
        case actionRequired
        case expectedExceptions
        case lastCheckedAt
    }
}

// MARK: - System State Enum

enum SystemState: String, Codable, Equatable {
    case unknown = "unknown"
    case checking = "checking"
    case healthy = "healthy"
    case attention = "attention"
    case error = "error"

    var displayName: String {
        switch self {
        case .unknown:
            return "État du système inconnu"
        case .checking:
            return "Vérification en cours…"
        case .healthy:
            return "Tout est à jour"
        case .attention:
            return "Éléments demandent votre attention"
        case .error:
            return "La vérification n'a pas pu être terminée"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .checking:
            return "hourglass"
        case .healthy:
            return "checkmark.circle.fill"
        case .attention:
            return "exclamationmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .unknown:
            return "gray"
        case .checking:
            return "blue"
        case .healthy:
            return "green"
        case .attention:
            return "orange"
        case .error:
            return "red"
        }
    }
}

// MARK: - Operation Status Enum

enum OperationStatus: String, Codable, CaseIterable {
    case queued = "queued"
    case running = "running"
    case succeeded = "succeeded"
    case partiallySucceeded = "partiallySucceeded"
    case failed = "failed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .queued:
            return "En attente"
        case .running:
            return "En cours"
        case .succeeded:
            return "Réussi"
        case .partiallySucceeded:
            return "Partiellement réussi"
        case .failed:
            return "Échoué"
        case .cancelled:
            return "Annulé"
        }
    }

    var symbolName: String {
        switch self {
        case .queued:
            return "clock"
        case .running:
            return "hourglass"
        case .succeeded:
            return "checkmark.circle.fill"
        case .partiallySucceeded:
            return "exclamationmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "xmark.circle"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .queued, .running:
            return false
        default:
            return true
        }
    }
}

// MARK: - Project State Enum

enum ProjectState: String, Codable, Equatable {
    case unknown = "unknown"
    case healthy = "healthy"
    case attention = "attention"
    case error = "error"
    case disabled = "disabled"

    var displayName: String {
        switch self {
        case .unknown:
            return "Non analysé"
        case .healthy:
            return "Sain"
        case .attention:
            return "Attention requise"
        case .error:
            return "Erreur"
        case .disabled:
            return "Désactivé"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .healthy:
            return "checkmark.circle.fill"
        case .attention:
            return "exclamationmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .disabled:
            return "xmark.circle"
        }
    }
}

// MARK: - Operation Context

struct OperationContext {
    let kind: String // "check", "scan", "import", "sync", "add_project", etc.
    let projectId: String?
    let skillId: String?
    let displayName: String
    let scope: OperationScope // "global", "project", "skill", "tool"

    enum OperationScope {
        case global
        case project(String)
        case skill(String, String) // project, skill
        case tool
    }
}

// MARK: - Operation Result

struct OperationResult {
    let context: OperationContext
    let status: OperationStatus
    let startedAt: Date
    let finishedAt: Date?
    let duration: TimeInterval?
    let summary: String
    let changes: OperationChanges?
    let warnings: [String]
    let error: OperationError?
    let stdout: String?
    let stderr: String?
    let exitCode: Int?
    let metadata: [String: String]
}

struct OperationChanges {
    let created: Int
    let updated: Int
    let unchanged: Int
    let deleted: Int

    var total: Int {
        created + updated + unchanged + deleted
    }
}

struct OperationError {
    let code: String
    let message: String
    let details: [String: String]?
    let retryable: Bool
    let writeState: WriteState
}

enum WriteState: String {
    case noChanges = "no_changes"
    case partialChanges = "partial_changes"
    case rolledBack = "rolled_back"
    case unknown = "unknown"
}
