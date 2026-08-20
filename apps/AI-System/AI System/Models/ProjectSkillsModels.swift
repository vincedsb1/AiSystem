import Foundation

// MARK: - Project Skills Backend Response Models

/// Schema version for project skills API.
/// Must be incremented when breaking changes are made.
let PROJECT_SKILLS_SCHEMA_VERSION = 1

// MARK: - List Projects Response

struct ListProjectsResponse: Codable, VersionedBackendPayload {
    let schemaVersion: Int
    let status: String
    let generatedAt: String
    let projects: [ProjectInfo]
    let error: BackendError?

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case status
        case generatedAt
        case projects
        case error
    }
}

struct ProjectInfo: Codable, Equatable, Identifiable {
    let name: String
    let root: String
    let enabled: Bool
    let paths: ProjectPaths
    /// Targets the project actually installs shared skills on.
    /// Absent on older payloads; defaults to codex-only, matching the backend.
    let sharedTargets: [String]?

    var id: String { name }

    var effectiveSharedTargets: [String] { sharedTargets ?? ["codex"] }

    func installsSharedSkills(on target: String) -> Bool {
        effectiveSharedTargets.contains(target)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case root
        case enabled
        case paths
        case sharedTargets
    }
}

struct ProjectPaths: Codable, Equatable {
    let codexSkills: String
    let claudeCommands: String

    enum CodingKeys: String, CodingKey {
        case codexSkills
        case claudeCommands
    }
}

// MARK: - Scan Project Response

struct ScanProjectResponse: Codable, VersionedBackendPayload {
    let schemaVersion: Int
    let status: String
    let generatedAt: String
    let project: ProjectInfo?
    let summary: SkillSummary?
    let skills: [SkillRow]
    let error: BackendError?

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case status
        case generatedAt
        case project
        case summary
        case skills
        case error
    }
}

struct SkillSummary: Codable, Equatable {
    let total: Int
    let managed: Int
    let unmanaged: Int
    let shared: Int
    let projectSpecific: Int
    let missingClaude: Int
    let missingCodex: Int
    let drift: Int
    let conflicts: Int
    let expectedExceptions: Int
    let actionRequired: Int

    enum CodingKeys: String, CodingKey {
        case total
        case managed
        case unmanaged
        case shared
        case projectSpecific
        case missingClaude
        case missingCodex
        case drift
        case conflicts
        case expectedExceptions
        case actionRequired
    }
}

struct SkillRow: Codable, Equatable, Identifiable {
    let name: String
    let canonicalId: String?
    let candidateCanonicalId: String?
    let scope: String?
    let sourceOfTruth: String?
    let description: String?
    let managed: Bool
    let importable: Bool
    let presence: SkillPresence
    let paths: SkillPaths
    let status: SkillStatus
    /// Backend-authoritative severity. `nil` when no action is required.
    let severity: ActionSeverity?
    /// Backend-authoritative list of actions the interface may offer.
    let allowedActions: [String]
    let exception: SkillException?
    let conflict: SkillConflict?

    var id: String { name }

    var requiresAction: Bool { severity != nil }

    enum CodingKeys: String, CodingKey {
        case name
        case canonicalId
        case candidateCanonicalId
        case scope
        case sourceOfTruth
        case description
        case managed
        case importable
        case presence
        case paths
        case status
        case severity
        case allowedActions
        case exception
        case conflict
    }
}

struct SkillPresence: Codable, Equatable {
    let codex: Bool
    let claude: Bool

    enum CodingKeys: String, CodingKey {
        case codex
        case claude
    }
}

struct SkillPaths: Codable, Equatable {
    let codex: String?
    let claude: String?
    let canonical: String?

    enum CodingKeys: String, CodingKey {
        case codex
        case claude
        case canonical
    }
}

struct SkillException: Codable, Equatable {
    let status: String
    let reason: String?
    let artifactType: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case status
        case reason
        case artifactType
        case name
    }
}

struct SkillConflict: Codable, Equatable {
    let code: String
    let message: String
    let details: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
    }
}

// MARK: - Backend Error

struct BackendError: Codable, Equatable {
    let code: String
    let message: String
    let details: [String: AnyCodable]?
    let retryable: Bool?
    let writeState: String?
    let suggestedAction: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
        case retryable
        case writeState
        case suggestedAction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        details = try container.decodeIfPresent([String: AnyCodable].self, forKey: .details)
        retryable = try container.decodeIfPresent(Bool.self, forKey: .retryable)
        writeState = try container.decodeIfPresent(String.self, forKey: .writeState)
        suggestedAction = try container.decodeIfPresent(String.self, forKey: .suggestedAction)
    }
}

// MARK: - Helper: AnyCodable for flexible JSON

/// A type-erased codable wrapper for flexible JSON dictionaries.
enum AnyCodable: Codable, Equatable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case object([String: AnyCodable])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: AnyCodable].self) {
            self = .object(object)
        } else {
            throw Swift.DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

// MARK: - Skill Status Enum

enum SkillStatus: String, Codable, Equatable, CaseIterable {
    case managedSynced = "managed_synced"
    case localCodexOnly = "local_codex_only"
    case localClaudeOnly = "local_claude_only"
    case localBothUnmanaged = "local_both_unmanaged"
    case missingClaude = "missing_claude"
    case missingCodex = "missing_codex"
    case canonicalDrift = "canonical_drift"
    case manifestError = "manifest_error"
    case conflict = "conflict"
    case expectedClaudeOnly = "expected_claude_only"
    case expectedCodexOnly = "expected_codex_only"

    var displayName: String {
        switch self {
        case .managedSynced:
            return "Synchronisé"
        case .localCodexOnly:
            return "Présent uniquement dans Codex"
        case .localClaudeOnly:
            return "Présent uniquement dans Claude"
        case .localBothUnmanaged:
            return "Non géré"
        case .missingClaude:
            return "Export Claude manquant"
        case .missingCodex:
            return "Export Codex manquant"
        case .canonicalDrift:
            return "Différent de la source"
        case .manifestError:
            return "Configuration invalide"
        case .conflict:
            return "Conflit à résoudre"
        case .expectedClaudeOnly:
            return "Claude uniquement — attendu"
        case .expectedCodexOnly:
            return "Codex uniquement — attendu"
        }
    }

    var requiresAction: Bool {
        switch self {
        case .managedSynced, .expectedClaudeOnly, .expectedCodexOnly:
            return false
        default:
            return true
        }
    }

    /// Expected exceptions are neither errors nor pending actions
    /// (FR-STATE-05).
    var isExpectedException: Bool {
        self == .expectedClaudeOnly || self == .expectedCodexOnly
    }

    var symbolName: String {
        switch self {
        case .managedSynced:
            return "checkmark.circle.fill"
        case .expectedClaudeOnly, .expectedCodexOnly:
            return "checkmark.circle"
        case .conflict, .manifestError:
            return "xmark.octagon.fill"
        case .canonicalDrift:
            return "arrow.triangle.branch"
        case .missingClaude, .missingCodex:
            return "arrow.triangle.2.circlepath"
        case .localCodexOnly, .localClaudeOnly, .localBothUnmanaged:
            return "tray.and.arrow.down"
        }
    }

    /// Human explanation shown under the title (spec 10.9).
    var explanation: String {
        switch self {
        case .managedSynced:
            return "Claude et Codex correspondent à la source gérée."
        case .localCodexOnly:
            return "Ce skill n'est pas encore géré par AI System."
        case .localClaudeOnly:
            return "Cette commande n'est pas encore gérée par AI System."
        case .localBothUnmanaged:
            return "Les deux versions existent hors source gérée."
        case .missingClaude:
            return "La source gérée existe mais l'export Claude est absent."
        case .missingCodex:
            return "La source gérée existe mais l'export Codex est absent."
        case .canonicalDrift:
            return "Un export ne correspond plus à la source gérée."
        case .manifestError:
            return "Le backend ne peut pas déterminer une configuration valide."
        case .conflict:
            return "Plusieurs sources ou destinations sont incompatibles."
        case .expectedClaudeOnly:
            return "Cette exception est déclarée et ne nécessite aucune action."
        case .expectedCodexOnly:
            return "Cette exception est déclarée et ne nécessite aucune action."
        }
    }
}
